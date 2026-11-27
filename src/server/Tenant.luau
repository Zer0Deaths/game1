--!strict
-- THE TENANT: SHIFT's first entity. A tall, faceless figure in a long coat
-- that hunts by SOUND.
--   * Dormant until the first Shift. When the lights come back after any
--     Shift, it arrives a few corridors away from the loudest player.
--   * Hears moving players (sprinting and heavy loads carry much further)
--     and dropped loot, and walks the maze to the noise.
--   * When it spots you it stops and shrieks first (Config.TENANT.noticeSeconds),
--     then chases: faster than walking, a little slower than sprinting.
--     Out of sight it only knows where it last saw you, so break line of
--     sight and go quiet to lose it.
--   * Hearing has a range per sound (Config.TENANT): walking carries a
--     few studs, sprinting a couple of cells, dropped loot further.
--   * Catching you kills you; your loot spills where you fell.
--   * The exit lift is safe: it won't take anyone standing inside it.
-- Counter: stay quiet, split up, don't drop loot near it.
--
-- Fully server-side and cheap: one anchored model, a maze-grid path search
-- (196 cells) a few times a second, and a handful of raycasts.
-- Its body is an R15-style rig (EntityRig): tall, thin, near-black and
-- featureless, animated on each player's device (Entities.client). Its
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

type State = "dormant" | "wander" | "investigate" | "notice" | "chase" | "linger"

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

	local function setState(s: State)
		state = s
		if model then
			model:SetAttribute("State", s)
		end
	end

	local function hide()
		if model then
			model.Parent = ServerStorage
		end
		route = {}
		target = nil
		lastSeenAt = nil
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
			return deeper * (if ctx.depth <= 1 then T.firstRunChaseScale else 1)
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
	end

	local function decide()
		local l = layout
		if not l or state == "dormant" or not model or model.Parent ~= workspace then
			return
		end
		local now = os.clock()

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

		-- 2. Sight: chase the nearest player it can see.
		local seen: Player? = nil
		local seenDist = T.sightRange
		for _, player in Players:GetPlayers() do
			local r = rootOf(player)
			if r and not inLift(r.Position) then
				local dist = (r.Position - position).Magnitude
				if dist <= seenDist and canSee(r.Position + Vector3.new(0, 1.5, 0)) then
					seen, seenDist = player, dist
				end
			end
		end
		if state == "notice" then
			if now < noticeUntil then
				return -- standing still, shrieking: your head start
			end
			setState("chase")
		end
		if seen then
			if state ~= "chase" then
				-- First it stops and shrieks. That's the warning to run.
				print(`[Tenant] crew {ctx.crew}: spotted {seen.Name}`)
				target = seen
				if model then
					model:SetAttribute("TargetId", seen.UserId) -- that player gets the reveal stinger
				end
				setState("notice")
				noticeUntil = now + T.noticeSeconds
				lastNoticed = now
				lastSeenAt = (rootOf(seen) :: BasePart).Position
				route = {}
				return
			end
			target = seen
			lastNoticed = now
			local r = rootOf(seen) :: BasePart
			lastSeenAt = r.Position
			goalCell = nil
			route = { Vector3.new(r.Position.X, 0, r.Position.Z) } -- straight at you: nothing is in the way
			return
		end

		-- 3. Hearing: head for the loudest noise in range.
		local heard = NoiseService.audible(position)
		local best: NoiseService.Noise? = nil
		for _, n in heard do
			if layout and LevelBuilder.inLevel(layout, n.position, ctx.origin) and not inLift(n.position) and (not best or n.radius - (n.position - position).Magnitude > best.radius - (best.position - position).Magnitude) then
				best = n
			end
		end
		if best then
			lastNoticed = now
			if state ~= "chase" then
				setState("investigate")
			end
			local cx, cz = cellOf(best.position, l)
			walkTo(cx, cz)
			if #route == 0 then
				-- Same cell as the noise: go to the exact spot.
				route = { Vector3.new(best.position.X, 0, best.position.Z) }
			end
			return
		end

		-- 4. Nothing seen or heard.
		if (state == "chase" or state == "investigate") and now - lastNoticed > T.forgetAfter then
			setState("wander")
			target = nil
			route = {}
		elseif state == "chase" and target and lastSeenAt then
			-- Lost sight: run to where it last saw them, then listen. It does
			-- not know where you went unless it hears you.
			local cx, cz = cellOf(lastSeenAt, l)
			if not goalCell or goalCell[1] ~= cx or goalCell[2] ~= cz then
				walkTo(cx, cz)
				if #route == 0 then
					route = { Vector3.new(lastSeenAt.X, 0, lastSeenAt.Z) }
				end
			elseif #route == 0 then
				setState("investigate") -- got there, you're gone: listen
				lastSeenAt = nil
			end
		end
		if #route == 0 and state ~= "chase" then
			if state == "investigate" and now - lastNoticed <= T.forgetAfter then
				return -- reached the noise; listen for a moment
			end
			setState("wander")
			wanderSomewhere()
		end
	end

	local function step(dt: number)
		if state == "dormant" or not model or model.Parent ~= workspace or not root then
			return
		end
		local moving = false
		if state ~= "linger" then
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
