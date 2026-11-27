--!strict
-- THE TENANT: SHIFT's first entity. A tall, faceless figure in a long coat
-- that hunts by SOUND.
--   * Dormant until the first Shift. When the lights come back after any
--     Shift, it arrives a few corridors away from the loudest player.
--   * Hears moving players (sprinting and heavy loads carry much further)
--     and dropped loot, and walks the maze to the noise.
--   * It sees what's in front of it (Config.TENANT.sightCone), not behind.
--     When it spots you it stops, lifts its pale face at you and screeches
--     (Config.TENANT.noticeSeconds) before it moves: that's your warning.
--     Get out of sight in that time and it doesn't chase, it walks to where
--     it saw you. If it does chase, it sets off slowly and runs about as
--     fast as you walk on sublevel 1 (a sprint always pulls away).
--   * Out of sight it only knows where it last saw you: it walks there,
--     stands and listens, and only then follows sounds, a step behind
--     (it re-aims every Config.TENANT.rethinkSeconds). Break line of sight
--     and go quiet to lose it.
--   * Hearing has a range per sound (Config.TENANT): walking carries a
--     few studs, sprinting a couple of cells, dropped loot further.
--   * Catching you kills you; your loot spills where you fell.
--   * The exit lift is safe: it won't take anyone standing inside it.
--   * A melee hit stuns it (MeleeService sets StunnedUntil, a server time,
--     and StunFrom, the hitter's position, on its model): it reels away
--     from the hit and stands still, can't take anyone and forgets who it
--     was after. It comes round dazed (Config.TENANT.dazedSeconds, blind)
--     and wanders off rather than going straight back for the hitter.
-- Counter: stay quiet, split up, don't drop loot near it.
--
-- Fully server-side and cheap: one anchored model, a maze-grid path search
-- (196 cells) a few times a second, and a handful of raycasts.
-- Its body is an R15-style rig (EntityRig): tall, thin and near-black with
-- a bone-white face that catches a faint light, so you can make it out in
-- the dark; animated on each player's device (Entities.client). Its
-- one cue, a wet clicking breath, is played there too (Cues.client).
-- The tubes around it stutter, so you mostly catch it in the flicker.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local NoiseService = require(script.Parent:WaitForChild("NoiseService"))
local EntityRig = require(script.Parent:WaitForChild("EntityRig"))

local T = Config.TENANT
local DECIDE_EVERY = 0.25

local Tenant = {}

type State = "dormant" | "wander" | "investigate" | "notice" | "chase" | "linger" | "stunned"

-- Public -----------------------------------------------------------------------

export type Tenant = { destroy: () -> () }

-- One Tenant in a crew's level (Sublevels may make two deeper down).
-- Dormant until the first Shift ends, or from the start deeper down.
function Tenant.create(ctx: any): Tenant
	local crewState: Folder = ctx.state
	local alive = true
	local layout: LevelGen.Layout? = ctx.layout
	local model: Model? = nil
	local root: BasePart? = nil
	local state: State = "dormant"
	local position = Vector3.zero
	local wasShifting = false -- only a real blackout ending (true -> false) brings it in
	local graceUntil = 0 -- no kills for a moment after it arrives
	local facing = 0 -- yaw in radians
	local route: { Vector3 } = {}
	local goalCell: { number }? = nil
	local target: Player? = nil
	local lastNoticed = 0
	local lingerUntil = 0
	local noticeUntil = 0 -- it stops and shrieks before every chase
	local lastSeenAt: Vector3? = nil -- where it last saw its target (it can't see through walls)
	local loudness: { [Player]: number } = {} -- running average of how loud each player is
	local chaseSince = 0 -- when this chase started (it builds up to full speed)
	local searching = false -- walking to where it lost you (deaf until it gets there)
	local listenUntil = 0 -- standing still, listening
	local nextRethink = 0 -- when it may re-aim at a sound
	local lostAt = -math.huge -- when it last lost sight of someone it was running after
	local lost: Player? = nil
	local blindUntil = 0 -- dazed after a stun: it can't see anyone yet
	local faceLight: PointLight? = nil


	-- Helpers --------------------------------------------------------------------

	local function cellOf(pos: Vector3, l: LevelGen.Layout): (number, number)
		return LevelBuilder.cellOf(l, pos, ctx.origin)
	end

	local function rootOf(player: Player): BasePart?
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local r = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		-- Only people actually in the level (not waiting in the safehouse).
		if humanoid and humanoid.Health > 0 and r and layout and LevelBuilder.inLevel(layout, r.Position, ctx.origin) then
			return r
		end
		return nil
	end

	local function inLift(pos: Vector3): boolean
		local lift = crewState:GetAttribute("LiftPosition")
		if typeof(lift) ~= "Vector3" then
			return false
		end
		local d = pos - lift
		return Vector3.new(d.X, 0, d.Z).Magnitude <= Config.LIFT_RADIUS + 1
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local function canSee(pos: Vector3): boolean
		local eye = position + Vector3.new(0, T.height * 0.85, 0)
		local exclude: { Instance } = {}
		if model then
			table.insert(exclude, model)
		end
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(exclude, p.Character)
			end
		end
		rayParams.FilterDescendantsInstances = exclude
		return workspace:Raycast(eye, pos - eye, rayParams) == nil
	end

	local function lookVector(): Vector3
		return Vector3.new(-math.sin(facing), 0, -math.cos(facing))
	end

	local function faceToward(pos: Vector3)
		local flat = Vector3.new(pos.X - position.X, 0, pos.Z - position.Z)
		if flat.Magnitude > 0.1 then
			facing = math.atan2(-flat.X, -flat.Z)
		end
	end

	-- Can it see this player? Only in front of it, unless they're right
	-- next to it, or they're who it's already running after.
	local function sees(player: Player, r: BasePart): boolean
		local flat = Vector3.new(r.Position.X - position.X, 0, r.Position.Z - position.Z)
		local dist = flat.Magnitude
		if dist > T.sightRange then
			return false
		end
		local locked = state == "chase" and player == target
		if dist > T.senseRange and not locked and flat.Unit:Dot(lookVector()) < T.sightCone then
			return false
		end
		return canSee(r.Position + Vector3.new(0, 1.5, 0))
	end

	local function setState(s: State)
		state = s
		if model then
			model:SetAttribute("State", s)
		end
		if faceLight then
			faceLight.Brightness = if s == "notice" then T.faceGlowNotice else T.faceGlow
		end
	end

	local function hide()
		if model then
			model.Parent = ServerStorage
		end
		route = {}
		target = nil
		lastSeenAt = nil
		searching = false
		listenUntil = 0
	end

	local function show()
		if model then
			model.Parent = workspace
		end
	end

	-- Plan a walk to a cell along the maze.
	local function walkTo(cx: number, cz: number)
		local l = layout
		if not l then
			return
		end
		local sx, sz = cellOf(position, l)
		local cells = LevelGen.path(l, sx, sz, cx, cz)
		route = {}
		goalCell = { cx, cz }
		if cells then
			for _, c in cells do
				table.insert(route, LevelBuilder.cellCenter(c[1], c[2], ctx.origin))
			end
		end
	end

	local function speed(): number
		if state == "chase" then
			local D = Config.DEPTH
			local deeper = math.min(D.tenantSpeedCap, T.chaseSpeed + D.tenantSpeedPerDepth * (ctx.depth - 1))
			local full = deeper * (if ctx.depth <= 1 then T.firstRunChaseScale else 1)
			-- It sets off slowly and builds up to a run.
			local ramp = math.clamp((os.clock() - chaseSince) / math.max(0.01, T.chaseRampSeconds), 0, 1)
			return T.investigateSpeed + (full - T.investigateSpeed) * ramp
		elseif state == "investigate" then
			return T.investigateSpeed
		end
		return T.wanderSpeed
	end

	-- Arrival after a Shift --------------------------------------------------------

	local function loudestPlayer(): Player?
		local best: Player? = nil
		local bestScore = -1
		for _, player in Players:GetPlayers() do
			local r = rootOf(player)
			if r and not inLift(r.Position) then
				local score = loudness[player] or 0
				if score > bestScore then
					best, bestScore = player, score
				end
			end
		end
		return best
	end

	local function arrive()
		local l = layout
		if not l or not model then
			return
		end
		local victim = loudestPlayer()
		local victimRoot = victim and rootOf(victim)
		if not victim or not victimRoot then
			return
		end
		-- Distances from every living player, to keep it a fair way from all of them.
		local fromEach: { { [number]: number } } = {}
		for _, player in Players:GetPlayers() do
			local r = rootOf(player)
			if r then
				local px, pz = cellOf(r.Position, l)
				table.insert(fromEach, LevelGen.distancesFrom(l, px, pz))
			end
		end
		local vx, vz = cellOf(victimRoot.Position, l)
		local fromVictim = LevelGen.distancesFrom(l, vx, vz)
		local candidates: { number } = {}
		local farthestKey, farthestDist = nil :: number?, -1
		for key, d in fromVictim do
			local nearest = math.huge
			for _, dist in fromEach do
				nearest = math.min(nearest, dist[key] or math.huge)
			end
			if nearest >= T.arriveMinCells and d <= T.arriveMaxCells then
				table.insert(candidates, key)
			end
			if nearest > farthestDist then
				farthestKey, farthestDist = key, nearest
			end
		end
		local key = if #candidates > 0 then candidates[math.random(1, #candidates)] else farthestKey
		if not key then
			return
		end
		position = LevelBuilder.cellCenter(key // 1000, key % 1000, ctx.origin)
		show()
		-- It comes looking for whoever was loudest.
		setState("investigate")
		target = nil
		searching = false
		listenUntil = 0
		lastNoticed = os.clock()
		walkTo(vx, vz)
		graceUntil = os.clock() + T.arriveGraceSeconds
		print(`[Tenant] crew {ctx.crew}: arrived {fromVictim[key]} cells from {victim.Name}`)
	end

	-- Brain ------------------------------------------------------------------------

	local function wanderSomewhere()
		local l = layout
		if not l then
			return
		end
		local sx, sz = cellOf(position, l)
		local dist = LevelGen.distancesFrom(l, sx, sz)
		local options: { number } = {}
		for key, d in dist do
			if d >= 2 and d <= 6 then
				table.insert(options, key)
			end
		end
		if #options > 0 then
			local key = options[math.random(1, #options)]
			walkTo(key // 1000, key % 1000)
		end
	end

	local function take(player: Player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if model then
			model:SetAttribute("AttackAt", workspace:GetServerTimeNow()) -- clients play the lunge
		end
		if humanoid then
			humanoid.Health = 0
		end
		ctx.notify(`{player.DisplayName} was taken by the Tenant.`, "warn")
		print(`[Tenant] crew {ctx.crew}: took {player.Name}`)
		setState("linger")
		lingerUntil = os.clock() + T.killCooldown
		route = {}
		target = nil
		searching = false
		listenUntil = 0
	end

	-- Walk (not run) to where it last saw someone, then stand and listen.
	local function searchAt(at: Vector3?)
		local l = layout
		setState("investigate")
		lastNoticed = os.clock()
		route = {}
		searching = at ~= nil and l ~= nil
		if at and l then
			local cx, cz = cellOf(at, l)
			walkTo(cx, cz)
			if #route == 0 then
				route = { Vector3.new(at.X, 0, at.Z) }
			end
		end
	end

	local function stunned(): boolean
		local untilAt = model and model:GetAttribute("StunnedUntil")
		return typeof(untilAt) == "number" and workspace:GetServerTimeNow() < untilAt
	end

	local function decide()
		local l = layout
		if not l or state == "dormant" or not model or model.Parent ~= workspace then
			return
		end
		local now = os.clock()

		-- 0. Stunned by a melee hit: it reels away from the hitter, stands,
		-- and drops whoever it was after. Then it comes round dazed.
		if stunned() then
			if state ~= "stunned" then
				setState("stunned")
				route = {}
				target = nil
				lost = nil
				lastSeenAt = nil
				searching = false
				listenUntil = 0
				local from = (model :: Model):GetAttribute("StunFrom")
				if typeof(from) == "Vector3" then
					faceToward(position * 2 - from) -- turned away from the blow
				end
			end
			return
		elseif state == "stunned" then
			setState("wander")
			route = {}
			blindUntil = now + T.dazedSeconds
			lastNoticed = now
		end

		-- 1. Anyone within reach is taken (except inside the lift).
		for _, player in Players:GetPlayers() do
			local r = rootOf(player)
			if r and not inLift(r.Position) then
				local d = r.Position - position
				if Vector3.new(d.X, 0, d.Z).Magnitude <= T.killRange and state ~= "linger" and now >= graceUntil then
					take(player)
					return
				end
			end
		end
		if state == "linger" then
			if now < lingerUntil then
				return
			end
			setState("wander")
		end

		-- 2. Sight: the nearest player it can see.
		local seen: Player? = nil
		local seenRoot: BasePart? = nil
		local seenDist = math.huge
		for _, player in Players:GetPlayers() do
			local r = rootOf(player)
			if r and not inLift(r.Position) then
				local dist = (r.Position - position).Magnitude
				if dist < seenDist and now >= blindUntil and sees(player, r) then
					seen, seenRoot, seenDist = player, r, dist
				end
			end
		end

		-- The warning: it stands, faces you and screeches. Only if it can
		-- still see you at the end does it run.
		if state == "notice" then
			local r = target and rootOf(target)
			local still = r ~= nil and not inLift(r.Position) and (r.Position - position).Magnitude <= T.sightRange and canSee(r.Position + Vector3.new(0, 1.5, 0))
			if still then
				lastSeenAt = (r :: BasePart).Position
				faceToward((r :: BasePart).Position)
			end
			if now < noticeUntil then
				return
			end
			if still then
				setState("chase")
				chaseSince = now
				lastNoticed = now
				local at = (r :: BasePart).Position
				route = { Vector3.new(at.X, 0, at.Z) }
			else
				searchAt(lastSeenAt) -- you got out of sight in time: it comes to look, at a walk
			end
			return
		end

		if seen and seenRoot then
			if state ~= "chase" then
				print(`[Tenant] crew {ctx.crew}: spotted {seen.Name}`)
				target = seen
				if model then
					model:SetAttribute("TargetId", seen.UserId) -- that player gets the reveal stinger
				end
				setState("notice")
				-- Someone it lost a moment ago gets a shorter warning (still a screech).
				local again = seen == lost and now - lostAt <= T.forgetAfter
				noticeUntil = now + (if again then T.renoticeSeconds else T.noticeSeconds)
				lastNoticed = now
				lastSeenAt = seenRoot.Position
				faceToward(seenRoot.Position)
				searching = false
				listenUntil = 0
				route = {}
				return
			end
			target = seen
			lastNoticed = now
			lastSeenAt = seenRoot.Position
			goalCell = nil
			route = { Vector3.new(seenRoot.Position.X, 0, seenRoot.Position.Z) } -- straight at you: nothing is in the way
			return
		end

		-- 3. Lost sight mid-chase: it stops running and walks to where it
		-- last saw you. It doesn't know where you went.
		if state == "chase" then
			lost, lostAt = target, now
			searchAt(lastSeenAt)
			return
		end

		-- 4. Got there: it stands still and listens before it does anything.
		if searching then
			if #route > 0 then
				return
			end
			searching = false
			listenUntil = now + T.listenSeconds
			lastNoticed = now
			return
		end
		if now < listenUntil then
			return
		end

		-- 5. Hearing: head for the loudest noise in range. It re-aims only
		-- every rethinkSeconds, so it is always a step behind someone moving.
		if now >= nextRethink then
			local heard = NoiseService.audible(position)
			local best: NoiseService.Noise? = nil
			for _, n in heard do
				if layout and LevelBuilder.inLevel(layout, n.position, ctx.origin) and not inLift(n.position) and (not best or n.radius - (n.position - position).Magnitude > best.radius - (best.position - position).Magnitude) then
					best = n
				end
			end
			if best then
				nextRethink = now + T.rethinkSeconds
				lastNoticed = now
				setState("investigate")
				local cx, cz = cellOf(best.position, l)
				walkTo(cx, cz)
				if #route == 0 then
					-- Same cell as the noise: go to the exact spot.
					route = { Vector3.new(best.position.X, 0, best.position.Z) }
				end
				return
			end
		end

		-- 6. Nothing seen or heard.
		if state == "investigate" then
			if now - lastNoticed <= T.forgetAfter then
				return -- still walking to the noise, or listening where it was
			end
			setState("wander")
			target = nil
			route = {}
		end
		if #route == 0 then
			setState("wander")
			wanderSomewhere()
		end
	end

	local function step(dt: number)
		if state == "dormant" or not model or model.Parent ~= workspace or not root then
			return
		end
		local moving = false
		if state ~= "linger" and state ~= "stunned" and not stunned() then
			local remaining = speed() * dt
			while remaining > 0 and #route > 0 do
				local goal = route[1]
				local flat = Vector3.new(goal.X - position.X, 0, goal.Z - position.Z)
				local dist = flat.Magnitude
				if dist < 0.05 then
					table.remove(route, 1)
					continue
				end
				facing = math.atan2(-flat.X, -flat.Z)
				if dist <= remaining then
					position = Vector3.new(goal.X, 0, goal.Z)
					table.remove(route, 1)
					remaining -= dist
				else
					position += flat.Unit * remaining
					remaining = 0
				end
				moving = true
			end
		end
		-- Only the root moves; the walk itself is animated on each device.
		model:PivotTo(CFrame.new(position) * CFrame.Angles(0, facing, 0))
		local gait = if not moving then "idle" elseif state == "chase" then "run" else "walk"
		if model:GetAttribute("Gait") ~= gait then
			model:SetAttribute("Gait", gait)
		end
	end


	model = EntityRig.build("Tenant", T.height)
	root = (model :: Model).PrimaryPart
	-- Its pale face catches a faint cold light (an attachment just in front
	-- of it, see EntityRig), so you can make it out in the dark.
	local glowAt = (model :: Model):FindFirstChild("FaceLight", true)
	if glowAt and glowAt:IsA("Attachment") and T.faceGlow > 0 then
		local light = Instance.new("PointLight")
		light.Name = "FaceGlow"
		light.Color = Color3.fromRGB(214, 222, 230)
		light.Range = 3.5
		light.Brightness = T.faceGlow
		light.Shadows = false
		light.Parent = glowAt
		faceLight = light
	end
	CollectionService:AddTag(model :: Model, "SHIFT_Tenant") -- clients hang its sounds on this
	;(model :: Model):SetAttribute("Crew", ctx.crew)
	hide()
	setState("dormant")

	local connections: { RBXScriptConnection } = {}
	table.insert(connections, Players.PlayerRemoving:Connect(function(player)
		loudness[player] = nil
	end))
	table.insert(connections, RunService.Heartbeat:Connect(step))
	-- Vanishes in the blackout, arrives when the lights come back. Only a
	-- real blackout ending (true -> false) counts: signals can be deferred.
	table.insert(connections, crewState:GetAttributeChangedSignal("Shifting"):Connect(function()
		if not alive or crewState:GetAttribute("State") ~= "playing" then
			return
		end
		if crewState:GetAttribute("Shifting") then
			wasShifting = true
			hide()
			setState("dormant")
		elseif wasShifting then
			wasShifting = false
			arrive()
		end
	end))
	task.spawn(function()
		while alive do
			task.wait(DECIDE_EVERY)
			if not alive then
				break
			end
			for _, player in Players:GetPlayers() do
				local r = NoiseService.playerRadius(player)
				loudness[player] = (loudness[player] or 0) * 0.98 + r * 0.02
			end
			if crewState:GetAttribute("State") ~= "playing" then
				if state ~= "dormant" then
					hide()
					setState("dormant")
				end
			else
				decide()
			end
		end
	end)
	-- Deeper down it's already in the level: it turns up a little after
	-- the crew lands, a fair way from everyone.
	if ctx.depth >= Config.DEPTH.tenantAtStartFrom then
		task.spawn(function()
			task.wait(8 + math.random() * 6)
			while alive and state == "dormant" and not crewState:GetAttribute("Shifting") do
				arrive()
				if state ~= "dormant" then
					break
				end
				task.wait(2)
			end
		end)
	end

	return {
		destroy = function()
			alive = false
			for _, c in connections do
				c:Disconnect()
			end
			if model then
				model:Destroy()
			end
		end,
	}
end

return Tenant
