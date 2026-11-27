--!strict
-- ExitLift: the deposit point inside each level. Walk onto the pad while
-- carrying artefacts and they are sold into the shared quota.
-- It sits in the cell furthest from the spawn (see LevelGen exit).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Surfaces = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Surfaces"))
local Meshes = require(script.Parent:WaitForChild("Meshes"))

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

-- Builds the lift and returns the world position of the pad centre and
-- the lift model.
function ExitLift.build(center: Vector3, height: number, parent: Instance): (Vector3, Model)
	local model = Instance.new("Model")
	model.Name = "ExitLift"

	-- Steel floor plate with a glowing amber edge strip.
	local plate = part({
		Name = "Plate",
		Size = Vector3.new(10, 0.2, 10),
		Position = center + Vector3.new(0, 0.1, 0),
		Color = Color3.fromRGB(70, 70, 74),
		Material = Enum.Material.DiamondPlate,
	}, model)
	for _, edge in { Vector3.new(0, 0, 5), Vector3.new(0, 0, -5), Vector3.new(5, 0, 0), Vector3.new(-5, 0, 0) } do
		local along = if edge.X == 0 then Vector3.new(10, 0.12, 0.3) else Vector3.new(0.3, 0.12, 10)
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
	for _, corner in { Vector3.new(5, 0, 5), Vector3.new(-5, 0, 5), Vector3.new(5, 0, -5), Vector3.new(-5, 0, -5) } do
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
	light.Range = 22
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

	-- Control panel on one post: Go deeper / Return to safehouse, enabled
	-- once the quota is met and the whole crew is aboard (Sublevels).
	local panel = part({
		Name = "Panel",
		Size = Vector3.new(1.2, 1.8, 0.4),
		CFrame = CFrame.new(center + Vector3.new(4.6, 3.6, 4.6)) * CFrame.Angles(0, math.rad(45), 0),
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
	model.Parent = parent
	-- The Blender cage (deck, posts, header, ropes, lamp guard, control box)
	-- for the 11-stud levels. The edge strips and the lamp stay these parts:
	-- they turn green when the quota's met. The panel keeps its prompts.
	if height == 11 then
		table.insert(cage, panel)
		Meshes.dress("exit_lift", CFrame.new(center), model, cage)
	end
	return center, model
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
