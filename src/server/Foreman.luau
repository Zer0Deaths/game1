--!strict
-- THE FOREMAN: SHIFT's closing-time entity (from Config.FOREMAN.fromDepth).
-- When the sublevel timer reaches Config.FOREMAN.startAt seconds, the lift
-- dings and the Foreman starts switching the level off. It goes from the
-- cells furthest from the lift (by the route you'd walk) in toward it, a
-- cell at a time, breakers clunking, until only the lift's own cell is lit
-- Config.FOREMAN.liftAt seconds before the timer runs out. Anyone standing
-- in a cell it has switched off is taken.
--
-- The dark edge moves in exactly fast enough to reach the lift on time, so
-- anyone already walking back keeps ahead of it. It only catches the people
-- who were never going to make it, and it catches them sooner: the timer
-- becomes something you can see coming down the corridor. It walks that
-- edge, just inside the dark, on the route of whoever it's about to catch:
-- broad, in a hard hat, nothing under the brim, keys on its belt.
--
-- Fair play:
--   * the lift's cell is never switched off, and the lift is always safe,
--   * it waits out a Shift's blackout; afterwards it works the routes out
--     again (the lift may have moved) and never leaves anyone in the dark
--     because a wall moved: the edge waits behind the furthest player,
--   * the Quiet never strikes while it's working (one says freeze, this
--     one says move).
--
-- State for clients (the crew's CrewState, mirrored onto Workspace):
--   ForemanActive  true while it's switching the level off
-- Every light it switches off gets LightState "dead" and the attribute
-- Switched = true: clients clunk the breaker and darken it on the map.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local EntityRig = require(script.Parent:WaitForChild("EntityRig"))

local F = Config.FOREMAN
local TICK = 0.1
local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

local Foreman = {}

export type Foreman = { destroy: () -> (), force: () -> () }

function Foreman.create(ctx: any): Foreman
	local state: Folder = ctx.state
	local alive = true
	local active = false
	local forced = false
	local front = math.huge -- cells further than this from the lift (by route) are switched off
	local rate = 0 -- cells per second the edge moves in
	local dist: { [number]: number } = {}
	local liftKey = 0
	local switched: { [number]: boolean } = {}
	local inDark: { [Player]: number } = {}
	local shiftSeen = (state:GetAttribute("ShiftCount") or 0) :: number
	local wasShifting = false
	local bodyAt: Vector3? = nil

	-- Built when it clocks on (late in the level, so the Blender model has
	-- long since loaded).
	local body: Model? = nil
	local function getBody(): Model
		if not body then
			local b = EntityRig.build("Foreman", F.height)
			b:SetAttribute("Crew", ctx.crew)
			b:SetAttribute("Gait", "idle")
			b.Parent = ServerStorage
			body = b
		end
		return body :: Model
	end

	local function timeLeft(): number
		return ((state:GetAttribute("EndsAt") or math.huge) :: number) - workspace:GetServerTimeNow()
	end

	local function rootOf(player: Player): BasePart?
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local r = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and humanoid.Health > 0 and r and LevelBuilder.inLevel(ctx.layout, r.Position, ctx.origin) then
			return r
		end
		return nil
	end

	local function inLift(r: BasePart): boolean
		local offset = r.Position - (ctx.lift :: Vector3)
		return Vector3.new(offset.X, 0, offset.Z).Magnitude <= Config.LIFT_RADIUS and math.abs(offset.Y) < 8
	end

	local function keyOf(r: BasePart): number
		local x, z = LevelBuilder.cellOf(ctx.layout, r.Position, ctx.origin)
		return x * 1000 + z
	end

	-- Every player still out in the level (alive, not in the lift), with the
	-- length of their route back.
	local function outThere(): { { player: Player, root: BasePart, key: number, d: number } }
		local out = {}
		for _, p in Players:GetPlayers() do
			local r = rootOf(p)
			if r and not inLift(r) then
				local key = keyOf(r)
				local d = dist[key]
				if d then
					table.insert(out, { player = p, root = r, key = key, d = d })
				end
			end
		end
		return out
	end

	local function mapRoutes()
		local l = ctx.layout
		liftKey = l.exit.x * 1000 + l.exit.z
		dist = LevelGen.distancesFrom(l, l.exit.x, l.exit.z)
	end

	-- Aim the edge so it reaches the lift Config.FOREMAN.liftAt seconds
	-- before the end, starting from `from` (cells), never in front of anyone.
	local function schedule(from: number)
		local furthest = 0
		for _, o in outThere() do
			furthest = math.max(furthest, o.d)
		end
		front = math.max(from, furthest + F.margin)
		rate = math.max(0, front - 0.5) / math.max(1, timeLeft() - F.liftAt)
	end

	-- Switch off every cell beyond the edge (and keep switched cells off).
	local function switchOff(): number
		local l = ctx.layout
		local changed = 0
		for x = 1, l.width do
			for z = 1, l.depth do
				local key = x * 1000 + z
				local d = dist[key]
				local beyond = key ~= liftKey and (d == nil or d > front)
				if (beyond or switched[key]) and l.cells[x][z].light ~= "dead" then
					l.cells[x][z].light = "dead"
					changed += 1
				end
				if beyond and not switched[key] then
					switched[key] = true
					changed += 1
					local panel = LevelBuilder.lightPanel(ctx.model, key)
					if panel then
						panel:SetAttribute("Switched", true)
					end
				end
			end
		end
		if changed > 0 then
			LevelBuilder.applyLights(l, ctx.model)
		end
		return changed
	end

	local function start()
		active = true
		shiftSeen = (state:GetAttribute("ShiftCount") or 0) :: number
		mapRoutes()
		local far = 0
		for _, d in dist do
			far = math.max(far, d)
		end
		schedule(far)
		-- A few seconds' head start: the first breakers go after F.headStart,
		-- and the edge still reaches the lift on time.
		rate = math.max(0, front - 0.5) / math.max(1, timeLeft() - F.liftAt - F.headStart)
		front += rate * F.headStart
		state:SetAttribute("ForemanActive", true)
		ctx.notify(`{math.ceil(timeLeft())} SECONDS. The Foreman is switching off the level. Get to the lift.`, "banner")
		print(`[Foreman] crew {ctx.crew}: switching off from {far} cells out, {string.format("%.2f", rate)} cells/s`)
	end

	-- From a player's cell, walk away from the lift until the first switched
	-- off cell: where the Foreman stands, on their route, just in the dark.
	local function edgeBehind(key: number): number?
		local l = ctx.layout
		local k = key
		for _ = 1, 400 do
			local d = dist[k]
			if d == nil then
				return nil
			end
			if switched[k] then
				return k
			end
			local x, z = k // 1000, k % 1000
			local best, bestD = nil, d
			for _, dir in DIRS do
				local nk = (x + dir[1]) * 1000 + (z + dir[2])
				local nd = dist[nk]
				if nd and nd > bestD and not LevelGen.hasWall(l, x, z, dir[1], dir[2]) then
					best, bestD = nk, nd
				end
			end
			if not best then
				return nil
			end
			k = best
		end
		return nil
	end

	local function place(pos: Vector3, facing: Vector3?)
		local b = getBody()
		local look = if facing and (facing - pos).Magnitude > 0.1 then Vector3.new(facing.X, pos.Y, facing.Z) else pos + Vector3.new(0, 0, -1)
		b:PivotTo(CFrame.lookAt(pos, look))
		bodyAt = pos
		if b.Parent ~= workspace then
			b.Parent = workspace
		end
	end

	local function setGait(gait: string)
		if body then
			body:SetAttribute("Gait", gait)
		end
	end

	-- Walk the edge nearest whoever is closest to it.
	local function walk()
		local out = outThere()
		table.sort(out, function(a, b)
			return a.d > b.d
		end)
		for _, o in out do
			local edge = edgeBehind(o.key)
			if edge then
				local c = LevelBuilder.cellCenter(edge // 1000, edge % 1000, ctx.origin)
				local target = Vector3.new(c.X, ctx.origin.Y, c.Z)
				local at = bodyAt
				if not at or (target - at).Magnitude > F.teleportStuds then
					place(target, o.root.Position)
					setGait("idle")
				else
					local gap = target - at
					-- A steady walk, or as fast as the edge is moving if that's faster.
					local speed = math.max(F.walkSpeed, rate * LevelBuilder.CELL * 1.2)
					local step = math.min(gap.Magnitude, speed * TICK)
					local moving = step > 0.05
					place(if moving then at + gap.Unit * step else at, o.root.Position)
					setGait(if moving then "walk" else "idle")
				end
				return
			end
		end
		setGait("idle")
	end

	local function take(player: Player, root: BasePart)
		local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		-- It's right behind you when the lights go.
		local back = root.Position - root.CFrame.LookVector * 2.5
		place(Vector3.new(back.X, ctx.origin.Y, back.Z), root.Position)
		getBody():SetAttribute("AttackAt", workspace:GetServerTimeNow())
		humanoid.Health = 0
		inDark[player] = nil
		ctx.notify(`{player.DisplayName} was still on the clock.`, "warn")
		print(`[Foreman] crew {ctx.crew}: took {player.Name}`)
	end

	local function tick()
		local playing = state:GetAttribute("State") == "playing"
		local shifting = state:GetAttribute("Shifting") == true
		if not active then
			if playing and not shifting and (forced or ctx.depth >= F.fromDepth) and timeLeft() <= F.startAt then
				forced = false
				start()
			end
			return
		end
		if not playing then
			return
		end
		if shifting then
			wasShifting = true
			table.clear(inDark)
			return
		end
		local count = (state:GetAttribute("ShiftCount") or 0) :: number
		if wasShifting or count ~= shiftSeen then
			-- The walls (and maybe the lift) moved: work the routes out again.
			wasShifting = false
			shiftSeen = count
			mapRoutes()
			schedule(front)
			print(`[Foreman] crew {ctx.crew}: routes changed, edge at {string.format("%.1f", front)} cells`)
		end
		front = math.max(0.5, front - rate * TICK)
		switchOff()
		walk()
		for _, o in outThere() do
			if o.key ~= liftKey and o.d > front then
				inDark[o.player] = (inDark[o.player] or 0) + TICK
				if (inDark[o.player] :: number) >= F.grace then
					take(o.player, o.root)
				end
			else
				inDark[o.player] = nil
			end
		end
	end

	state:SetAttribute("ForemanActive", false)
	local conn = Players.PlayerRemoving:Connect(function(player)
		inDark[player] = nil
	end)
	task.spawn(function()
		while alive do
			task.wait(TICK)
			if alive then
				tick()
			end
		end
	end)
	return {
		destroy = function()
			alive = false
			conn:Disconnect()
			state:SetAttribute("ForemanActive", false)
			if body then
				body:Destroy()
			end
		end,
		force = function()
			forced = true
		end,
	}
end

return Foreman
