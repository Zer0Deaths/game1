--!strict
-- ExitLift: the deposit point inside each level. Walk onto the pad while
-- carrying artefacts and they are sold into the shared quota. The cage is
-- 16 x 16 studs (Config.LIFT_SIZE) with the armoury on its west side.
-- It sits in the cell furthest from the spawn (see LevelGen exit).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Surfaces = require(Shared:WaitForChild("Surfaces"))
local Meshes = require(script.Parent:WaitForChild("Meshes"))
local MeleeModels = require(script.Parent:WaitForChild("MeleeModels"))

local ExitLift = {}

local AMBER = Color3.fromRGB(255, 170, 60)

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local HALF = Config.LIFT_SIZE / 2 -- 8: the cage is 16 x 16 studs

export type BuildOpts = {
	beacon: boolean?, -- early sublevels: the LIFT sign shows through walls
}

-- The armoury against the west side of the cage: a steel cabinet with a
-- pegboard of weapons over it and an ARMOURY sign. E opens the lift shop
-- (melee weapons, bought with your Cash). Modelled like the Blender kit:
-- origin on the deck at the cabinet's middle, front -Z, then turned to
-- face into the lift (+X).
local function armoury(center: Vector3, model: Model)
	local frame = CFrame.new(center + Vector3.new(-(HALF - 0.95), 0.2, 0)) * CFrame.Angles(0, -math.pi / 2, 0)
	local holder = Instance.new("Model")
	holder.Name = "Armoury"
	holder.Parent = model
	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	local cabinet = part({
		Name = "Cabinet",
		Size = Vector3.new(6, 3, 1.4),
		CFrame = at(0, 1.5, 0.05),
		Color = Color3.fromRGB(62, 72, 64),
		Material = Enum.Material.Metal,
	}, holder)
	local board = part({
		Name = "Board",
		Size = Vector3.new(6, 4.2, 0.2),
		CFrame = at(0, 3 + 2.1, 0.62),
		Color = Color3.fromRGB(150, 140, 112),
		Material = Enum.Material.WoodPlanks,
	}, holder)
	local sign = part({
		Name = "ArmourySign",
		Size = Vector3.new(4, 0.8, 0.2),
		CFrame = at(0, 7.75, 0.5),
		Color = Color3.fromRGB(28, 26, 20),
		Material = Enum.Material.Metal,
		CanCollide = false,
	}, holder)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 1.6
	gui.PixelsPerStud = 50
	gui.Parent = sign
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.Code
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(230, 70, 50)
	text.Text = "ARMOURY"
	text.Parent = gui
	-- The weapons on sale hang on the board (their own models), each set
	-- out from the board by how far its head sticks out behind.
	local hang: { { any } } = { { "melee_pipe", -2.2, 0.32 }, { "melee_crowbar", -0.75, 0.38 }, { "melee_axe", 0.75, -0.2 }, { "melee_sledge", 2.2, -0.12 } }
	for _, h in hang do
		MeleeModels.build(h[1], at(h[2], 3.4, h[3]), holder)
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ArmouryPrompt"
	prompt.ActionText = "Buy weapons"
	prompt.ObjectText = "Armoury"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = cabinet
	Surfaces.autoAll(holder)
	-- The Blender armoury (cabinet, pegboard and hooks, sign housing).
	Meshes.dress("lift_armoury", frame, holder, { cabinet, board, sign })
end

-- Builds the lift and returns the world position of the pad centre and
-- the lift model.
function ExitLift.build(center: Vector3, height: number, parent: Instance, opts: BuildOpts?): (Vector3, Model)
	local o: BuildOpts = opts or {}
	local S = HALF * 2
	local model = Instance.new("Model")
	model.Name = "ExitLift"

	-- Steel floor plate with a glowing amber edge strip.
	local plate = part({
		Name = "Plate",
		Size = Vector3.new(S, 0.2, S),
		Position = center + Vector3.new(0, 0.1, 0),
		Color = Color3.fromRGB(70, 70, 74),
		Material = Enum.Material.DiamondPlate,
	}, model)
	for _, edge in { Vector3.new(0, 0, HALF), Vector3.new(0, 0, -HALF), Vector3.new(HALF, 0, 0), Vector3.new(-HALF, 0, 0) } do
		local along = if edge.X == 0 then Vector3.new(S, 0.12, 0.3) else Vector3.new(0.3, 0.12, S)
		part({
			Name = "Edge",
			Size = along,
			Position = center + edge + Vector3.new(0, 0.26, 0),
			Color = AMBER,
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
		}, model)
	end

	-- Four steel posts and a header frame, like an open freight lift cage.
	local cage: { BasePart } = { plate }
	for _, corner in { Vector3.new(HALF, 0, HALF), Vector3.new(-HALF, 0, HALF), Vector3.new(HALF, 0, -HALF), Vector3.new(-HALF, 0, -HALF) } do
		table.insert(cage, part({
			Name = "Post",
			Size = Vector3.new(0.6, height, 0.6),
			Position = center + corner + Vector3.new(0, height / 2, 0),
			Color = Color3.fromRGB(90, 88, 80),
			Material = Enum.Material.CorrodedMetal,
		}, model))
	end

	-- Warm light so the lift reads as "safe" from down a corridor.
	local lamp = part({
		Name = "Lamp",
		Size = Vector3.new(2, 0.3, 2),
		Position = center + Vector3.new(0, height - 0.6, 0),
		Color = AMBER,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
	}, model)
	local light = Instance.new("PointLight")
	light.Color = AMBER
	light.Range = 26
	light.Brightness = 2
	light.Parent = lamp

	local sign = Instance.new("BillboardGui")
	sign.Name = "Sign"
	sign.Size = UDim2.fromOffset(220, 56)
	sign.StudsOffset = Vector3.new(0, 2, 0)
	sign.MaxDistance = 90
	sign.LightInfluence = 0
	sign.Parent = lamp
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Code
	label.TextScaled = true
	label.TextColor3 = AMBER
	label.TextStrokeTransparency = 0.4
	label.Text = "EXIT LIFT\nDEPOSIT HERE"
	label.Parent = sign
	if o.beacon then
		-- Sublevels 1-2: a small, faint LIFT marker you can see through the
		-- walls from anywhere in the level. Deeper down you find it by the
		-- compass alone. It moves with the lift after a Shift.
		local beacon = Instance.new("BillboardGui")
		beacon.Name = "Beacon"
		beacon.Size = UDim2.fromOffset(70, 26)
		beacon.StudsOffset = Vector3.new(0, 1, 0)
		beacon.AlwaysOnTop = true
		beacon.MaxDistance = 2000
		beacon.LightInfluence = 0
		beacon.Parent = lamp
		local b = Instance.new("TextLabel")
		b.Name = "Text"
		b.Size = UDim2.fromScale(1, 1)
		b.BackgroundTransparency = 1
		b.Font = Enum.Font.Code
		b.TextScaled = true
		b.TextColor3 = AMBER
		b.TextTransparency = 0.25
		b.TextStrokeTransparency = 0.6
		b.Text = "[ LIFT ]"
		b.Parent = beacon
	end

	-- Control panel on one post: Go deeper / Return to safehouse, enabled
	-- once the quota is met and the whole crew is aboard (Sublevels).
	local panel = part({
		Name = "Panel",
		Size = Vector3.new(1.2, 1.8, 0.4),
		CFrame = CFrame.new(center + Vector3.new(HALF - 0.4, 3.6, HALF - 0.4)) * CFrame.Angles(0, math.rad(45), 0),
		Color = Color3.fromRGB(46, 44, 40),
		Material = Enum.Material.Metal,
		CanCollide = false,
	}, model)
	local function prompt(name: string, action: string, key: Enum.KeyCode)
		local pr = Instance.new("ProximityPrompt")
		pr.Name = name
		pr.ActionText = action
		pr.ObjectText = "Lift"
		pr.KeyboardKeyCode = key
		pr.HoldDuration = 0.6
		pr.MaxActivationDistance = 12
		pr.RequiresLineOfSight = false
		pr.Enabled = false
		pr.Parent = panel
	end
	prompt("Deeper", "Go deeper", Enum.KeyCode.E)
	prompt("Surface", "Return to safehouse", Enum.KeyCode.R)

	Surfaces.autoAll(model) -- PBR steel, rust and paint
	armoury(center, model)
	model.Parent = parent
	-- The Blender cage (deck, posts, header, ropes, lamp guard, control box)
	-- for the 11-stud levels. The edge strips and the lamp stay these parts:
	-- they turn green when the quota's met. The panel keeps its prompts.
	-- Only a cage modelled at this size: the old 10 x 10 mesh would sit
	-- inside the new posts.
	local size = Meshes.size("exit_lift")
	if height == 11 and size and size.X > S - 1 then
		table.insert(cage, panel)
		Meshes.dress("exit_lift", CFrame.new(center), model, cage)
	end
	return center, model
end

-- The armoury's prompt (Sublevels opens the lift shop from it).
function ExitLift.armouryPrompt(model: Model): ProximityPrompt?
	local holder = model:FindFirstChild("Armoury")
	local cabinet = holder and holder:FindFirstChild("Cabinet")
	return cabinet and cabinet:FindFirstChild("ArmouryPrompt") :: ProximityPrompt?
end

local GREEN = Color3.fromRGB(120, 255, 150)

-- Quota met: the lift turns green and says so. `aboard` / `needed` show
-- how many of the crew are inside.
function ExitLift.setReady(model: Model, ready: boolean, aboard: number?, needed: number?)
	local colour = if ready then GREEN else AMBER
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "Edge" or p.Name == "Lamp") then
			p.Color = colour
		end
	end
	local lamp = model:FindFirstChild("Lamp")
	local light = lamp and lamp:FindFirstChildOfClass("PointLight")
	if light then
		light.Color = colour
	end
	local label = lamp and lamp:FindFirstChild("Sign") and (lamp :: any).Sign:FindFirstChildOfClass("TextLabel")
	if label then
		label.TextColor3 = colour
		label.Text = if ready then `QUOTA MET\nALL ABOARD  {aboard or 0}/{needed or 0}` else "EXIT LIFT\nDEPOSIT HERE"
	end
end

-- The two choices on the panel.
function ExitLift.prompts(model: Model): (ProximityPrompt, ProximityPrompt)
	local panel = model:FindFirstChild("Panel") :: BasePart
	return panel:FindFirstChild("Deeper") :: ProximityPrompt, panel:FindFirstChild("Surface") :: ProximityPrompt
end

return ExitLift
