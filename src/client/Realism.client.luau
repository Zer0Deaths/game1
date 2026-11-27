--!strict
-- Realism: the air and the small life in the rooms, on this device only
-- (nothing here touches the server or other players).
--   * Light shafts: a very faint cone of light under each lit fitting near
--     you, and slow dust drifting through it. Only the nearest few lights
--     get one (Config.SHAFTS_MAX within Config.SHAFT_RADIUS); the same few
--     rigs are moved from light to light as you walk, so a 900-light level
--     costs the same as the safehouse. A shaft goes out with its light
--     (blackouts, flickers, dead tubes).
--   * Safehouse: two fittings with a bad starter, the EXIT sign's stutter,
--     the stopped clock's twitching second hand, and a dimmer ambient so
--     the tubes throw pools of light with darkness between them.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "LocalRealism"
folder.Parent = workspace

-- LIGHT SHAFTS AND DUST ----------------------------------------------------------

-- Safehouse fittings with a bad starter (filled in further down).
type Flicker = { glow: BasePart, light: SurfaceLight, tubes: { BasePart }, nextAt: number, burst: number, off: boolean, until_: number }
local flickers: { [BasePart]: Flicker } = {}

-- Every light that can carry a shaft: level fittings and safehouse tubes.
local lights: { [BasePart]: SurfaceLight } = {}
local function addLight(inst: Instance)
	if inst:IsA("BasePart") then
		local l = inst:FindFirstChildOfClass("SurfaceLight") or inst:WaitForChild("SurfaceLight", 5)
		if l and l:IsA("SurfaceLight") and inst.Parent then
			lights[inst] = l
		end
	end
end
for _, tag in { "LightFitting", "HubFixture" } do
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
		task.spawn(addLight, inst)
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(inst)
		lights[inst :: any] = nil
	end)
	for _, inst in CollectionService:GetTagged(tag) do
		task.spawn(addLight, inst)
	end
end

type Rig = {
	top: Attachment,
	bottom: Attachment,
	beam: Beam,
	dust: Part,
	emitter: ParticleEmitter,
	part: BasePart?,
	light: SurfaceLight?,
	nominal: number,
	state: number, -- last applied brightness step (-1 = off)
}

local rigs: { Rig } = {}
local function newRig(): Rig
	local top = Instance.new("Attachment")
	top.Name = "ShaftTop"
	top.Parent = workspace.Terrain
	local bottom = Instance.new("Attachment")
	bottom.Name = "ShaftBottom"
	bottom.Parent = workspace.Terrain
	local beam = Instance.new("Beam")
	beam.Attachment0 = top
	beam.Attachment1 = bottom
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 1
	beam.Texture = ""
	beam.Enabled = false
	beam.Parent = folder
	local dust = Instance.new("Part")
	dust.Name = "DustPool"
	dust.Anchored = true
	dust.CanCollide = false
	dust.CanQuery = false
	dust.CanTouch = false
	dust.CastShadow = false
	dust.Transparency = 1
	dust.Size = Vector3.new(4, 8, 4)
	dust.Parent = folder
	local e = Instance.new("ParticleEmitter")
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Rate = 3
	e.Lifetime = NumberRange.new(8, 13)
	e.Speed = NumberRange.new(0.03, 0.18)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, -0.02, 0)
	e.Drag = 0.5
	e.RotSpeed = NumberRange.new(-20, 20)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 0.05),
		NumberSequenceKeypoint.new(0.8, 0.04),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.3),
		NumberSequenceKeypoint.new(0.75, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.LightEmission = 0.3
	e.LightInfluence = 1 -- bright in the pool, gone in the dark
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Enabled = false
	e.Parent = dust
	return { top = top, bottom = bottom, beam = beam, dust = dust, emitter = e, part = nil, light = nil, nominal = 2, state = -2 }
end
for _ = 1, Config.SHAFTS_MAX do
	table.insert(rigs, newRig())
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function release(r: Rig)
	r.part, r.light = nil, nil
	r.beam.Enabled = false
	r.emitter.Enabled = false
	r.state = -2
end

local function assign(r: Rig, part: BasePart, light: SurfaceLight)
	r.part, r.light = part, light
	r.nominal = math.max(light.Brightness, 0.5)
	local top = part.Position - Vector3.new(0, part.Size.Y / 2 + 0.05, 0)
	-- Find the floor under the light (ignoring people and these effects).
	rayParams.FilterDescendantsInstances = { folder, player.Character :: any }
	local hit = workspace:Raycast(top, Vector3.new(0, -24, 0), rayParams)
	local floorY = if hit then hit.Position.Y else top.Y - 11
	local height = math.max(2, top.Y - floorY)
	r.top.WorldPosition = top
	r.bottom.WorldPosition = Vector3.new(top.X, floorY + 0.3, top.Z)
	local w = math.min(part.Size.X, part.Size.Z)
	r.beam.Width0 = math.clamp(w * 1.3, 1.5, 3.5)
	r.beam.Width1 = math.clamp(height * 0.95, 6, 12)
	r.beam.Color = ColorSequence.new(light.Color)
	r.dust.Size = Vector3.new(r.beam.Width1 * 0.45, height * 0.85, r.beam.Width1 * 0.45)
	r.dust.Position = Vector3.new(top.X, floorY + height / 2, top.Z)
	r.emitter.Color = ColorSequence.new(light.Color:Lerp(Color3.new(1, 1, 1), 0.5))
	r.state = -2
end

-- Show or hide a rig with its light; scale the shaft with the light's brightness.
local function follow(r: Rig)
	local part, light = r.part, r.light
	if not part or not light then
		return
	end
	local lit = light.Enabled and light.Brightness > 0.05 and part.Parent ~= nil
	if lit and part.Material ~= Enum.Material.Neon and part.Transparency < 1 then
		lit = false -- a level panel switched to its dead/blackout look
	end
	local step = if lit then math.clamp(math.floor(light.Brightness / r.nominal * 8 + 0.5), 1, 10) else -1
	if step == r.state then
		return
	end
	r.state = step
	r.beam.Enabled = lit
	r.emitter.Enabled = lit
	if lit then
		local op = Config.SHAFT_OPACITY * step / 8
		r.beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1 - op),
			NumberSequenceKeypoint.new(0.65, 1 - op * 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
end

-- Every quarter second: hand the rigs to the nearest lit lights.
local nextPick = 0
local function pick(now: number)
	if now < nextPick then
		return
	end
	nextPick = now + 0.25
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local here = cam.CFrame.Position
	local radius = Config.SHAFT_RADIUS
	local near: { { part: BasePart, light: SurfaceLight, d: number } } = {}
	for part, light in lights do
		if not part.Parent then
			lights[part] = nil
			continue
		end
		local p = part.Position
		local dx, dz = p.X - here.X, p.Z - here.Z
		if math.abs(dx) < radius and math.abs(dz) < radius and math.abs(p.Y - here.Y) < 20 then
			local d = dx * dx + dz * dz
			local candidate = light.Enabled or flickers[part] ~= nil or CollectionService:HasTag(part, "FlickerLight")
			if d < radius * radius and candidate then
				table.insert(near, { part = part, light = light, d = d })
			end
		end
	end
	table.sort(near, function(a, b)
		return a.d < b.d
	end)
	local wanted: { [BasePart]: SurfaceLight } = {}
	for i = 1, math.min(#near, #rigs) do
		wanted[near[i].part] = near[i].light
	end
	-- Keep rigs that are still on a wanted light; free the rest.
	local free: { Rig } = {}
	for _, r in rigs do
		if r.part and wanted[r.part] then
			wanted[r.part] = nil
		else
			release(r)
			table.insert(free, r)
		end
	end
	for part, light in wanted do
		local r = table.remove(free)
		if not r then
			break
		end
		assign(r, part, light)
	end
end

-- SAFEHOUSE ------------------------------------------------------------------------

local function addFixture(glow: Instance)
	if not glow:IsA("BasePart") then
		return
	end
	local model = glow.Parent
	if not (model and model:GetAttribute("Flicker")) then
		return
	end
	local light = glow:FindFirstChildOfClass("SurfaceLight") or glow:WaitForChild("SurfaceLight", 5)
	if not (light and light:IsA("SurfaceLight")) then
		return
	end
	local tubes = {}
	for _, d in model:GetChildren() do
		if d.Name == "Tube" and d:IsA("BasePart") then
			table.insert(tubes, d)
		end
	end
	flickers[glow] = { glow = glow, light = light, tubes = tubes, nextAt = os.clock() + 2 + math.random() * 5, burst = 0, off = false, until_ = 0 }
end
CollectionService:GetInstanceAddedSignal("HubFixture"):Connect(function(inst)
	task.spawn(addFixture, inst)
end)
for _, inst in CollectionService:GetTagged("HubFixture") do
	task.spawn(addFixture, inst)
end

local TUBE_ON: { [BasePart]: Color3 } = {}
local function setTubes(f: Flicker, on: boolean)
	f.off = not on
	f.light.Enabled = on
	for _, t in f.tubes do
		TUBE_ON[t] = TUBE_ON[t] or t.Color
		t.Material = if on then Enum.Material.Neon else Enum.Material.Glass
		t.Color = if on then TUBE_ON[t] else Color3.fromRGB(70, 68, 60)
	end
end

local function stepFlickers(now: number)
	for glow, f in flickers do
		if not glow.Parent then
			flickers[glow] = nil
			continue
		end
		if now >= f.nextAt and f.burst == 0 then
			f.burst = math.random(2, 7) -- a stutter of 2-7 blinks
			f.until_ = now
		end
		if f.burst > 0 and now >= f.until_ then
			setTubes(f, f.off) -- toggle
			if not f.off then
				f.burst -= 1
			end
			f.until_ = now + (if f.off then 0.03 + math.random() * 0.09 else 0.04 + math.random() * 0.2)
			if f.burst == 0 then
				setTubes(f, true)
				f.nextAt = now + 3 + math.random() * 9
			end
		end
	end
end

-- The EXIT sign: a dying ballast, it drops out for a moment now and then.
local exitNext, exitUntil = os.clock() + 4, 0
local function stepExit(now: number)
	for _, box in CollectionService:GetTagged("HubExitSign") do
		local gui = box:FindFirstChildOfClass("SurfaceGui")
		local text = gui and gui:FindFirstChildOfClass("TextLabel")
		local glow = box:FindFirstChildOfClass("PointLight")
		if not text then
			continue
		end
		if now >= exitNext then
			exitUntil = now + 0.05 + math.random() * 0.18
			exitNext = now + (if math.random() < 0.35 then 0.15 else 2 + math.random() * 6)
		end
		local out = now < exitUntil
		text.TextTransparency = if out then 0.75 else 0
		if glow then
			glow.Enabled = not out
		end
	end
end

-- The stopped clock: the second hand keeps trying to move and can't.
local clockNext = 0
local function stepClock(now: number)
	if now < clockNext then
		return
	end
	clockNext = now + 1
	for _, face in CollectionService:GetTagged("HubClock") do
		local hand = face:FindFirstChild("Second", true)
		if hand and hand:IsA("GuiObject") then
			hand.Rotation = 42 * 6 + 4
			task.delay(0.12, function()
				hand.Rotation = 42 * 6
			end)
		end
	end
end

-- A dimmer ambient in the safehouse, once the join-time brightening is over.
local joined = os.clock()
local dimmed = false
local function stepAmbient(now: number, dt: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local p = cam.CFrame.Position - Config.HUB_ORIGIN
	local inHub = math.abs(p.X) < 40 and math.abs(p.Z) < 30 and p.Y > -5 and p.Y < 20
	if inHub and now - joined > Config.START_AMBIENT_HOLD + Config.START_AMBIENT_FADE + 0.5 then
		local a = math.min(1, dt * 1.2)
		Lighting.Ambient = Lighting.Ambient:Lerp(Config.HUB_AMBIENT, a)
		Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(Config.HUB_AMBIENT, a)
		dimmed = true
	elseif not inHub and dimmed then
		dimmed = false
		Lighting.Ambient = Config.AMBIENT
		Lighting.OutdoorAmbient = Config.AMBIENT
	end
end

RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	stepFlickers(now)
	pick(now)
	for _, r in rigs do
		follow(r)
	end
	stepExit(now)
	stepClock(now)
	stepAmbient(now, dt)
end)
