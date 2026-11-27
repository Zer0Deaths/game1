--!strict
-- THE TENANT: SHIFT's first entity. A tall, faceless figure in a long coat
-- that hunts by SOUND.
--   * Dormant until the first Shift. When the lights come back after any
--     Shift, it arrives a few corridors away from the loudest player.
--   * Hears moving players (sprinting and heavy loads carry much further)
--     and dropped loot, and walks the maze to the noise.
--   * When it spots you it stops and shrieks first (Config.TENANT.noticeSeconds),
--     then chases. Slower than walking, so you can always get away if you
--     keep moving; dead ends and hesitation are what kill you.
--   * Catching you kills you; your loot spills where you fell.
--   * The exit lift is safe: it won't take anyone standing inside it.
-- Counter: stay quiet, split up, don't drop loot near it.
--
-- Fully server-side and cheap: one anchored model, a maze-grid path search
-- (196 cells) a few times a second, and a handful of raycasts.
-- Built from basic shapes. A modelled creature would need an asset.
-- Its sounds are played on each player's device (TenantSounds.client).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local NoiseService = require(script.Parent:WaitForChild("NoiseService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local T = Config.TENANT
local CELL = LevelBuilder.CELL
local DECIDE_EVERY = 0.25

local Tenant = {}

type State = "dormant" | "wander" | "investigate" | "notice" | "chase" | "linger"

local layout: LevelGen.Layout? = nil
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
local loudness: { [Player]: number } = {} -- running average of how loud each player is

-- Body -----------------------------------------------------------------------

local COAT = Color3.fromRGB(44, 40, 34)
local SKIN = Color3.fromRGB(172, 166, 146)

local function shape(m: Model, name: string, size: Vector3, offset: CFrame, colour: Color3, material: Enum.Material, round: boolean?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = colour
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CFrame = offset
	if round then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	p.Parent = m
	return p
end

-- A cylinder from point a to point b (Roblox cylinders run along X).
local function limb(m: Model, name: string, a: Vector3, b: Vector3, thick: number, colour: Color3, material: Enum.Material)
	local p = shape(m, name, Vector3.new((b - a).Magnitude, thick, thick), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), colour, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function joint(m: Model, name: string, at: Vector3, size: number, colour: Color3, material: Enum.Material)
	local p = shape(m, name, Vector3.new(size, size, size), CFrame.new(at), colour, material)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Built from rounded primitives: jointed legs, a hunched spine under a
-- long coat, arms that hang past the knees with long fingers, and a smooth
-- featureless head pushed forward. A real modelled mesh would still be
-- better (see TODO.md); this is as far as code-built shapes go.
local function buildBody(): Model
	local m = Instance.new("Model")
	m.Name = "Tenant"
	local h = T.height / 9.5 -- everything scales with height
	local function v(x: number, y: number, z: number): Vector3
		return Vector3.new(x, y, z) * h
	end
	local base = shape(m, "Root", Vector3.new(2, 0.2, 2), CFrame.new(), COAT, Enum.Material.SmoothPlastic)
	base.Transparency = 1
	m.PrimaryPart = base
	local TROUSERS = Color3.fromRGB(30, 28, 25)
	local fabric, skin = Enum.Material.Fabric, Enum.Material.SmoothPlastic

	for _, side in { -1, 1 } do
		-- Legs: thigh, knee, shin, foot.
		local hip, knee, ankle, toe = v(side * 0.42, 4.4, 0), v(side * 0.5, 2.3, -0.22), v(side * 0.44, 0.3, 0.05), v(side * 0.46, 0.12, -0.75)
		limb(m, "Thigh", hip, knee, 0.55 * h, TROUSERS, fabric)
		joint(m, "Knee", knee, 0.5 * h, TROUSERS, fabric)
		limb(m, "Shin", knee, ankle, 0.42 * h, TROUSERS, fabric)
		limb(m, "Foot", ankle, toe, 0.36 * h, TROUSERS, Enum.Material.Leather)
		-- Arms: coat sleeve to the elbow, then long bare forearms.
		local shoulder, elbow, wrist = v(side * 1.05, 7.15, -0.7), v(side * 1.28, 4.95, -0.95), v(side * 1.18, 2.55, -1.15)
		joint(m, "Shoulder", shoulder, 0.72 * h, COAT, fabric)
		limb(m, "UpperArm", shoulder, elbow, 0.44 * h, COAT, fabric)
		joint(m, "Elbow", elbow, 0.36 * h, SKIN, skin)
		limb(m, "Forearm", elbow, wrist, 0.3 * h, SKIN, skin)
		joint(m, "Hand", wrist, 0.36 * h, SKIN, skin)
		for f = -1, 1 do
			local tip = wrist + v(side * (0.08 + f * 0.1), -1.05 + math.abs(f) * 0.15, -0.12 + f * 0.08)
			limb(m, "Finger", wrist, tip, 0.08 * h, SKIN, skin)
		end
	end
	-- Hunched spine under the coat: two coat sections bent forward.
	local hunch = CFrame.Angles(math.rad(-16), 0, 0)
	shape(m, "CoatLower", v(1.75, 2.4, 1.0), CFrame.new(v(0, 4.2, 0.05)) * CFrame.Angles(math.rad(-5), 0, 0), COAT, fabric)
	shape(m, "CoatUpper", v(1.95, 2.6, 1.05), CFrame.new(v(0, 6.2, -0.35)) * hunch, COAT, fabric)
	-- Coat tails hanging behind the legs, flaring slightly.
	for _, side in { -1, 1 } do
		shape(m, "CoatTail", v(0.9, 2.6, 0.12), CFrame.new(v(side * 0.5, 2.0, 0.5)) * CFrame.Angles(math.rad(8), 0, math.rad(side * 6)), COAT, fabric)
	end
	shape(m, "Collar", v(1.5, 0.5, 0.9), CFrame.new(v(0, 7.45, -0.75)) * hunch, COAT, fabric)
	-- A smooth, featureless head pushed forward on a long neck.
	local neckBase, neckTop = v(0, 7.35, -0.8), v(0, 8.2, -1.35)
	limb(m, "Neck", neckBase, neckTop, 0.36 * h, SKIN, skin)
	shape(m, "Head", v(0.95, 1.6, 1.1), CFrame.new(v(0, 8.75, -1.6)) * CFrame.Angles(math.rad(-25), 0, 0), SKIN, skin, true)
	return m
end

-- Helpers --------------------------------------------------------------------

local function cellOf(pos: Vector3, l: LevelGen.Layout): (number, number)
	return math.clamp(math.floor(pos.X / CELL) + 1, 1, l.width), math.clamp(math.floor(pos.Z / CELL) + 1, 1, l.depth)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local r = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	-- Only people actually in the level (not waiting in the safehouse).
	if humanoid and humanoid.Health > 0 and r and layout and LevelBuilder.inLevel(layout, r.Position) then
		return r
	end
	return nil
end

local function inLift(pos: Vector3): boolean
	local lift = workspace:GetAttribute("LiftPosition")
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
			table.insert(route, LevelBuilder.cellCenter(c[1], c[2]))
		end
	end
end

local function speed(): number
	if state == "chase" then
		local firstRun = ((workspace:GetAttribute("RunNumber") or 1) :: number) <= 1
		return T.chaseSpeed * (if firstRun then T.firstRunChaseScale else 1)
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
	position = LevelBuilder.cellCenter(key // 1000, key % 1000)
	show()
	-- It comes looking for whoever was loudest.
	setState("investigate")
	target = nil
	lastNoticed = os.clock()
	walkTo(vx, vz)
	graceUntil = os.clock() + T.arriveGraceSeconds
	print(`[Tenant] arrived {fromVictim[key]} cells from {victim.Name}`)
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
	if humanoid then
		humanoid.Health = 0
	end
	Remotes.Notify:FireAllClients(`{player.DisplayName} was taken by the Tenant.`, "warn")
	print(`[Tenant] took {player.Name}`)
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
			print(`[Tenant] spotted {seen.Name}`)
			target = seen
			setState("notice")
			noticeUntil = now + T.noticeSeconds
			lastNoticed = now
			route = {}
			return
		end
		target = seen
		lastNoticed = now
		local r = rootOf(seen) :: BasePart
		route = { Vector3.new(r.Position.X, 0, r.Position.Z) } -- straight at you: nothing is in the way
		return
	end

	-- 3. Hearing: head for the loudest noise in range.
	local heard = NoiseService.audible(position)
	local best: NoiseService.Noise? = nil
	for _, n in heard do
		if layout and LevelBuilder.inLevel(layout, n.position) and not inLift(n.position) and (not best or n.radius - (n.position - position).Magnitude > best.radius - (best.position - position).Magnitude) then
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
	elseif state == "chase" and target then
		-- Lost sight: keep after their last known cell for a while.
		local r = rootOf(target)
		if r then
			local cx, cz = cellOf(r.Position, l)
			if not goalCell or goalCell[1] ~= cx or goalCell[2] ~= cz or #route == 0 then
				walkTo(cx, cz)
			end
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
	-- A slow, heavy lurch from side to side while it walks.
	local t = os.clock()
	local sway = if moving then math.sin(t * speed() * 0.45) * 0.05 else math.sin(t * 0.8) * 0.015
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, facing, 0) * CFrame.Angles(0, 0, sway))
end

-- Public -----------------------------------------------------------------------

-- A fresh level: the Tenant goes dormant until the next Shift.
function Tenant.setLevel(newLayout: LevelGen.Layout)
	layout = newLayout
	if model then
		model:Destroy()
	end
	model = buildBody()
	root = (model :: Model).PrimaryPart
	model:SetAttribute("State", "dormant")
	wasShifting = false
	hide()
	setState("dormant")
end

function Tenant.init()
	if not T.enabled then
		return
	end
	-- Track how loud each player has been lately (who it comes for after a Shift).
	task.spawn(function()
		while true do
			task.wait(DECIDE_EVERY)
			for _, player in Players:GetPlayers() do
				local r = NoiseService.playerRadius(player)
				loudness[player] = (loudness[player] or 0) * 0.98 + r * 0.02
			end
			if workspace:GetAttribute("RunState") ~= "playing" then
				if state ~= "dormant" then
					hide()
					setState("dormant")
				end
			else
				decide()
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		loudness[player] = nil
	end)
	RunService.Heartbeat:Connect(step)
	-- Vanishes in the blackout, arrives when the lights come back.
	workspace:GetAttributeChangedSignal("Shifting"):Connect(function()
		if workspace:GetAttribute("RunState") ~= "playing" then
			return
		end
		-- Signals can be deferred, so a level reset (Shifting set to false)
		-- may only arrive here once the run has started. Only a real
		-- blackout ending counts.
		if workspace:GetAttribute("Shifting") then
			wasShifting = true
			hide()
			setState("dormant")
		elseif wasShifting then
			wasShifting = false
			arrive()
		end
	end)
end

return Tenant
