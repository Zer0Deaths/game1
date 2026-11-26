--!strict
-- Safehouse: the crews' hub between runs. A warm, lit break room away from
-- the level with:
--   * the spawn (everyone arrives here, and comes back here after dying)
--   * a crew board: four signs, one per crew; use one to join that crew
--   * the shop counter (opens the shop on your screen)
--   * the descent lift: press Ready; when everyone is ready, or the
--     countdown ends, every crew goes down together. During a run it lets
--     late joiners (but not the dead) join in.
-- Built from basic parts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Safehouse = {}

local W, D, H = 64, 44, 12 -- room size in studs
local WARM = Color3.fromRGB(255, 214, 160)
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

local function textOn(p: BasePart, face: Enum.NormalId, text: string, colour: Color3, size: number?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.PixelsPerStud = 40
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Code
	label.TextScaled = size == nil
	label.TextSize = size or 14
	label.TextWrapped = true
	label.TextColor3 = colour
	label.Text = text
	label.Parent = gui
	gui.Parent = p
	return label
end

local function prompt(parent: Instance, action: string, object: string): ProximityPrompt
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = object
	pr.MaxActivationDistance = 10
	pr.RequiresLineOfSight = false
	pr.Parent = parent
	return pr
end

export type Hub = {
	model: Model,
	spawn: SpawnLocation,
	arrivalCFrame: (index: number) -> CFrame,
	crewSigns: { TextLabel },
	crewPrompts: { ProximityPrompt },
	shopPrompt: ProximityPrompt,
	wardrobePrompt: ProximityPrompt,
	supplyPrompt: ProximityPrompt,
	readyPrompt: ProximityPrompt,
	liftSign: TextLabel,
}

function Safehouse.build(): Hub
	local o = Config.HUB_ORIGIN
	local model = Instance.new("Model")
	model.Name = "Safehouse"

	-- Shell: floor, ceiling, four walls.
	part({ Name = "Floor", Size = Vector3.new(W, 1, D), Position = o + Vector3.new(0, -0.5, 0), Color = Color3.fromRGB(92, 70, 50), Material = Enum.Material.WoodPlanks }, model)
	part({ Name = "Ceiling", Size = Vector3.new(W, 1, D), Position = o + Vector3.new(0, H + 0.5, 0), Color = Color3.fromRGB(200, 192, 170), Material = Enum.Material.Plaster }, model)
	local wallColour = Color3.fromRGB(120, 112, 92)
	part({ Name = "WallN", Size = Vector3.new(W, H, 1), Position = o + Vector3.new(0, H / 2, -D / 2), Color = wallColour, Material = Enum.Material.Plaster }, model)
	part({ Name = "WallS", Size = Vector3.new(W, H, 1), Position = o + Vector3.new(0, H / 2, D / 2), Color = wallColour, Material = Enum.Material.Plaster }, model)
	part({ Name = "WallW", Size = Vector3.new(1, H, D), Position = o + Vector3.new(-W / 2, H / 2, 0), Color = wallColour, Material = Enum.Material.Plaster }, model)
	part({ Name = "WallE", Size = Vector3.new(1, H, D), Position = o + Vector3.new(W / 2, H / 2, 0), Color = wallColour, Material = Enum.Material.Plaster }, model)

	-- Warm lamps: this is the one place that feels safe.
	for x = -1, 1 do
		for z = -1, 1, 2 do
			local lamp = part({ Name = "Lamp", Size = Vector3.new(3, 0.3, 3), Position = o + Vector3.new(x * 20, H - 0.2, z * 10), Color = WARM, Material = Enum.Material.Neon, CanCollide = false, CastShadow = false }, model)
			local light = Instance.new("PointLight")
			light.Color = WARM
			light.Range = 26
			light.Brightness = 1.6
			light.Shadows = false
			light.Parent = lamp
		end
	end

	-- Title on the west wall.
	local titleBoard = part({ Name = "Title", Size = Vector3.new(0.2, 3, 16), Position = o + Vector3.new(-W / 2 + 0.6, 7, 0), Color = Color3.fromRGB(28, 26, 20), Material = Enum.Material.SmoothPlastic }, model)
	textOn(titleBoard, Enum.NormalId.Right, "SHIFT  ·  CREW SAFEHOUSE", AMBER)

	-- Spawn in the middle.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanTouch = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.Position = o + Vector3.new(0, 0.1, 0)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = model

	-- Crew board: four signs on the north wall.
	local crewSigns, crewPrompts = {}, {}
	for c = 1, Config.CREW_COUNT do
		local x = (c - (Config.CREW_COUNT + 1) / 2) * 12
		local board = part({ Name = `Crew{c}Sign`, Size = Vector3.new(9, 4, 0.3), Position = o + Vector3.new(x, 5, -D / 2 + 0.8), Color = Color3.fromRGB(30, 28, 22), Material = Enum.Material.SmoothPlastic }, model)
		part({ Name = "Stripe", Size = Vector3.new(9, 0.4, 0.32), Position = o + Vector3.new(x, 7.2, -D / 2 + 0.8), Color = Config.CREW_COLOURS[c], Material = Enum.Material.Neon, CanCollide = false }, model)
		table.insert(crewSigns, textOn(board, Enum.NormalId.Back, Config.CREW_NAMES[c], Config.CREW_COLOURS[c]))
		table.insert(crewPrompts, prompt(board, "Join crew", Config.CREW_NAMES[c]))
	end

	-- Shop counter on the east side.
	local counter = part({ Name = "ShopCounter", Size = Vector3.new(4, 3.5, 12), Position = o + Vector3.new(W / 2 - 6, 1.75, 0), Color = Color3.fromRGB(70, 56, 40), Material = Enum.Material.Wood }, model)
	local screen = part({ Name = "ShopScreen", Size = Vector3.new(0.3, 2.4, 4), Position = o + Vector3.new(W / 2 - 6, 4.8, 0), Color = Color3.fromRGB(20, 30, 24), Material = Enum.Material.Neon }, model)
	textOn(screen, Enum.NormalId.Left, "SUPPLIES", Color3.fromRGB(150, 230, 120))
	local shopPrompt = prompt(counter, "Open shop", "Supplies")

	-- Wardrobe and supply crate on the west side (only active once the
	-- matching pass/product IDs are set in Config.MONETISATION).
	local wardrobe = part({ Name = "Wardrobe", Size = Vector3.new(3, 8, 6), Position = o + Vector3.new(-W / 2 + 3, 4, -12), Color = Color3.fromRGB(80, 74, 64), Material = Enum.Material.Metal }, model)
	local wardrobePrompt = prompt(wardrobe, "Change suit colour", "Wardrobe")
	wardrobePrompt.Enabled = Config.MONETISATION.SUIT_COLOURS_PASS ~= 0
	local crate = part({ Name = "SupplyCrate", Size = Vector3.new(4, 3, 4), Position = o + Vector3.new(-W / 2 + 4, 1.5, 12), Color = Color3.fromRGB(110, 96, 60), Material = Enum.Material.WoodPlanks }, model)
	local supplyPrompt = prompt(crate, "Send a crew supply drop", "Supplies for your whole crew")
	supplyPrompt.Enabled = Config.MONETISATION.CREW_SUPPLY_PRODUCT ~= 0

	-- Descent lift on the south wall.
	local liftCentre = o + Vector3.new(0, 0, D / 2 - 7)
	part({ Name = "LiftPlate", Size = Vector3.new(10, 0.2, 10), Position = liftCentre + Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(70, 70, 74), Material = Enum.Material.DiamondPlate }, model)
	for _, corner in { Vector3.new(5, 0, 5), Vector3.new(-5, 0, 5), Vector3.new(5, 0, -5), Vector3.new(-5, 0, -5) } do
		part({ Name = "Post", Size = Vector3.new(0.6, H, 0.6), Position = liftCentre + corner + Vector3.new(0, H / 2, 0), Color = Color3.fromRGB(90, 88, 80), Material = Enum.Material.CorrodedMetal }, model)
	end
	local liftBoard = part({ Name = "LiftSign", Size = Vector3.new(10, 2.4, 0.3), Position = liftCentre + Vector3.new(0, 9, -5), Color = Color3.fromRGB(28, 26, 20), Material = Enum.Material.SmoothPlastic, CanCollide = false }, model)
	local liftSign = textOn(liftBoard, Enum.NormalId.Front, "DESCENT", AMBER)
	local readyPost = part({ Name = "ReadyPanel", Size = Vector3.new(1.2, 2, 0.4), Position = liftCentre + Vector3.new(4.2, 3.5, -5.2), Color = AMBER, Material = Enum.Material.Neon }, model)
	local readyPrompt = prompt(readyPost, "Ready", "Descent")

	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = workspace

	local function arrivalCFrame(index: number): CFrame
		local angle = index * 2.4
		local r = 3 + (index % 4)
		return CFrame.new(o + Vector3.new(math.cos(angle) * r, 3.5, math.sin(angle) * r))
	end

	return {
		model = model,
		spawn = spawn,
		arrivalCFrame = arrivalCFrame,
		crewSigns = crewSigns,
		crewPrompts = crewPrompts,
		shopPrompt = shopPrompt,
		wardrobePrompt = wardrobePrompt,
		supplyPrompt = supplyPrompt,
		readyPrompt = readyPrompt,
		liftSign = liftSign,
	}
end

return Safehouse
