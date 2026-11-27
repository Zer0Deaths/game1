--!strict
-- Safehouse: the crews' hub between runs. A warm, lit break room away from
-- the level with:
--   * the spawn (everyone arrives here, and comes back here after dying)
--   * a crew board: four signs, one per crew; use one to join that crew
--   * the shop counter (opens the shop on your screen)
--   * the descent lift: press Ready; when everyone is ready, or the
--     countdown ends, every crew goes down together. During a run it lets
--     late joiners (but not the dead) join in.
-- Built from basic parts, dressed to look lived in: wallpaper, worn
-- carpet and stained ceiling tiles (PBR), real fluorescent fittings that
-- throw pools of light with shadows, skirting, grime decals (Grime.luau),
-- crates, papers, cables, pinned notes, a duty roster and a stopped clock.
-- Dust, light shafts, the odd flickering tube and the EXIT sign's stutter
-- are done on each player's device (Realism.client).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Surfaces = require(Shared:WaitForChild("Surfaces"))
local Grime = require(script.Parent:WaitForChild("Grime"))

local Safehouse = {}

local W, D, H = 64, 44, 12 -- room size in studs
local WARM = Color3.fromRGB(255, 226, 168) -- warm yellow fluorescent
local AMBER = Color3.fromRGB(255, 170, 60)
local PAPER = Color3.fromRGB(226, 218, 192)
local INK = Color3.fromRGB(40, 36, 30)

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	-- PBR surfaces: yellowed wallpaper, worn carpet, acoustic ceiling
	-- tiles; everything else by its material. No SmoothPlastic.
	local named = ({
		WallN = "SHIFT_Wallpaper",
		WallS = "SHIFT_Wallpaper",
		WallW = "SHIFT_Wallpaper",
		WallE = "SHIFT_Wallpaper",
		Ceiling = "SHIFT_CeilingTile",
		Floor = "SHIFT_Carpet",
	} :: { [string]: string })[p.Name]
	if named then
		Surfaces.apply(p, named)
	else
		Surfaces.auto(p)
	end
	p.Parent = parent
	return p
end

local function textOn(p: BasePart, face: Enum.NormalId, text: string, colour: Color3, size: number?, font: Enum.Font?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.PixelsPerStud = 40
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = font or Enum.Font.Code
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

-- Small decorative part: no collisions, no shadows, ignored by raycasts.
local function bit(props: { [string]: any }, parent: Instance): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return part(props, parent)
end

-- A grime decal on an invisible holder (only once the decals are uploaded).
local function grime(parent: Instance, key: string, cf: CFrame, size: Vector3, face: Enum.NormalId, transparency: number?)
	Grime.patch(function(props)
		local p = Instance.new("Part")
		p.Anchored = true
		for k, v in props do
			(p :: any)[k] = v
		end
		p.Parent = parent
		return p
	end, key, cf, size, face, transparency)
end

-- A sheet of paper pinned to a wall, with handwriting on it. `cf` faces
-- out of the wall (-Z is into the room's side of the sheet's Front face).
local function note(parent: Instance, cf: CFrame, size: Vector2, text: string, colour: Color3?, pinColour: Color3?)
	local sheet = bit({ Name = "Note", Size = Vector3.new(size.X, size.Y, 0.03), CFrame = cf, Color = colour or PAPER, Material = Enum.Material.Plastic }, parent)
	local label = textOn(sheet, Enum.NormalId.Front, text, INK, nil, Enum.Font.PatrickHand)
	label.TextScaled = true
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.08, 0)
	pad.PaddingRight = UDim.new(0.08, 0)
	pad.PaddingTop = UDim.new(0.1, 0)
	pad.PaddingBottom = UDim.new(0.1, 0)
	pad.Parent = label
	label.Parent.LightInfluence = 1 -- the note is lit like the wall, not glowing
	if pinColour then
		bit({ Name = "Pin", Shape = Enum.PartType.Ball, Size = Vector3.new(0.16, 0.16, 0.16), CFrame = cf * CFrame.new(0, size.Y / 2 - 0.12, -0.06), Color = pinColour, Material = Enum.Material.Plastic }, parent)
	end
end

-- One fluorescent fitting: a steel housing, two tubes, a downward light
-- with shadows. Lit pools under each, darkness between.
local function fixture(parent: Instance, at: Vector3, flicker: boolean)
	local f = Instance.new("Model")
	f.Name = "Fixture"
	bit({ Name = "LightHousing", Size = Vector3.new(8, 0.3, 2.4), Position = at + Vector3.new(0, -0.15, 0), Color = Color3.fromRGB(176, 172, 160), Material = Enum.Material.Metal }, f)
	for _, side in { -1, 1 } do
		-- End caps the tubes plug into.
		bit({ Name = "TubeCap", Size = Vector3.new(0.3, 0.35, 2.0), Position = at + Vector3.new(side * 3.85, -0.45, 0), Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Metal }, f)
	end
	for _, dz in { -0.55, 0.55 } do
		bit({ Name = "Tube", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7.4, 0.26, 0.26), Position = at + Vector3.new(0, -0.48, dz), Color = WARM, Material = Enum.Material.Neon }, f)
	end
	local glow = bit({ Name = "Glow", Size = Vector3.new(7.4, 0.05, 1.8), Position = at + Vector3.new(0, -0.32, 0), Transparency = 1 }, f)
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Color = WARM
	light.Brightness = Config.HUB_LIGHT_BRIGHTNESS
	light.Range = Config.HUB_LIGHT_RANGE
	light.Angle = Config.HUB_LIGHT_ANGLE
	light.Shadows = true
	light.Parent = glow
	f:SetAttribute("Flicker", flicker)
	f.Parent = parent
	CollectionService:AddTag(glow, "HubFixture")
end

-- The clock on the north wall: stopped at 3:17 (its second hand twitches
-- on your screen, Realism.client).
local function clock(parent: Instance, cf: CFrame)
	bit({ Name = "ClockRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, 2.1, 2.1), CFrame = cf * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(40, 38, 34), Material = Enum.Material.Plastic }, parent)
	local face = bit({ Name = "ClockFace", Size = Vector3.new(1.8, 1.8, 0.05), CFrame = cf * CFrame.new(0, 0, -0.14), Transparency = 1 }, parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 1
	gui.CanvasSize = Vector2.new(200, 200)
	gui.Parent = face
	local dial = Instance.new("Frame")
	dial.Size = UDim2.fromScale(1, 1)
	dial.BackgroundColor3 = Color3.fromRGB(222, 214, 190)
	dial.BorderSizePixel = 0
	dial.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = dial
	for i = 0, 11 do
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromScale(0.03, 0.86)
		holder.Rotation = i * 30
		holder.Parent = dial
		local tick = Instance.new("Frame")
		tick.BackgroundColor3 = INK
		tick.BorderSizePixel = 0
		tick.Size = UDim2.fromScale(1, if i % 3 == 0 then 0.12 else 0.07)
		tick.Parent = holder
	end
	-- Hands: a transparent holder centred on the dial, rotated; the visible
	-- half is the top half, so it turns about the centre.
	local function hand(name: string, length: number, width: number, angle: number, colour: Color3)
		local holder = Instance.new("Frame")
		holder.Name = name
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromScale(width, length * 2)
		holder.Rotation = angle
		holder.ZIndex = 2
		holder.Parent = dial
		local arm = Instance.new("Frame")
		arm.BackgroundColor3 = colour
		arm.BorderSizePixel = 0
		arm.Size = UDim2.fromScale(1, 0.5)
		arm.ZIndex = 2
		arm.Parent = holder
	end
	hand("Hour", 0.24, 0.04, (3 + 17 / 60) * 30, INK)
	hand("Minute", 0.36, 0.025, 17 * 6, INK)
	hand("Second", 0.4, 0.01, 42 * 6, Color3.fromRGB(150, 40, 30))
	CollectionService:AddTag(face, "HubClock")
end

-- Everything that makes the room look used. Built once.
local function dress(model: Model, o: Vector3)
	local decor = Instance.new("Folder")
	decor.Name = "Dressing"
	decor.Parent = model

	-- Fluorescent fittings in two rows; two of them aren't well.
	for x = -1, 1 do
		for z = -1, 1, 2 do
			fixture(decor, o + Vector3.new(x * 20, H, z * 10), (x == 1 and z == -1) or (x == -1 and z == 1))
		end
	end

	-- Suspended ceiling grid: 4-stud acoustic tiles.
	for x = -W / 2 + 4, W / 2 - 4, 4 do
		bit({ Name = "GridX", Size = Vector3.new(0.22, 0.08, D), Position = o + Vector3.new(x, H - 0.04, 0), Color = Color3.fromRGB(160, 156, 140), Material = Enum.Material.Metal }, decor)
	end
	for z = -D / 2 + 4, D / 2 - 4, 4 do
		bit({ Name = "GridZ", Size = Vector3.new(W, 0.08, 0.22), Position = o + Vector3.new(0, H - 0.04, z), Color = Color3.fromRGB(160, 156, 140), Material = Enum.Material.Metal }, decor)
	end

	-- Skirting boards, scuffed dark wood.
	local SKIRT = Color3.fromRGB(96, 76, 48)
	bit({ Name = "Skirting", Size = Vector3.new(W - 1, 0.8, 0.3), Position = o + Vector3.new(0, 0.4, -D / 2 + 0.65), Color = SKIRT, Material = Enum.Material.Wood }, decor)
	bit({ Name = "Skirting", Size = Vector3.new(W - 1, 0.8, 0.3), Position = o + Vector3.new(0, 0.4, D / 2 - 0.65), Color = SKIRT, Material = Enum.Material.Wood }, decor)
	bit({ Name = "Skirting", Size = Vector3.new(0.3, 0.8, D - 1), Position = o + Vector3.new(-W / 2 + 0.65, 0.4, 0), Color = SKIRT, Material = Enum.Material.Wood }, decor)
	bit({ Name = "Skirting", Size = Vector3.new(0.3, 0.8, D - 1), Position = o + Vector3.new(W / 2 - 0.65, 0.4, 0), Color = SKIRT, Material = Enum.Material.Wood }, decor)

	-- Grime (decals, once uploaded). Faces point into the room:
	-- north wall Back, south Front, west Right, east Left.
	local nZ, sZ, wX, eX = -D / 2 + 0.52, D / 2 - 0.52, -W / 2 + 0.52, W / 2 - 0.52
	local function onNorth(x: number, y: number): CFrame
		return CFrame.new(o + Vector3.new(x, y, nZ))
	end
	local function onSouth(x: number, y: number): CFrame
		return CFrame.new(o + Vector3.new(x, y, sZ))
	end
	local function onWest(z: number, y: number): CFrame
		return CFrame.new(o + Vector3.new(wX, y, z))
	end
	local function onEast(z: number, y: number): CFrame
		return CFrame.new(o + Vector3.new(eX, y, z))
	end
	local NS = Enum.NormalId
	-- Dirt banked into every corner and in patches along the walls.
	for _, cfg in {
		{ onNorth(-W / 2 + 4, 1.9), Vector3.new(7, 2.2, 0.05), NS.Back },
		{ onNorth(W / 2 - 4, 1.9), Vector3.new(7, 2.2, 0.05), NS.Back },
		{ onSouth(-W / 2 + 4, 1.9), Vector3.new(7, 2.2, 0.05), NS.Front },
		{ onSouth(W / 2 - 4, 1.9), Vector3.new(7, 2.2, 0.05), NS.Front },
		{ onWest(-D / 2 + 4, 1.9), Vector3.new(0.05, 2.2, 7), NS.Right },
		{ onWest(D / 2 - 4, 1.9), Vector3.new(0.05, 2.2, 7), NS.Right },
		{ onEast(-D / 2 + 4, 1.9), Vector3.new(0.05, 2.2, 7), NS.Left },
		{ onEast(D / 2 - 4, 1.9), Vector3.new(0.05, 2.2, 7), NS.Left },
		{ onNorth(9, 1.8), Vector3.new(10, 2, 0.05), NS.Back },
		{ onEast(9, 1.8), Vector3.new(0.05, 2, 9), NS.Left },
	} do
		grime(decor, "corner_grime", cfg[1], cfg[2], cfg[3], 0.1)
	end
	-- Scuffs where people stand: under the crew board, round the lift, by the counter.
	for _, cfg in {
		{ onNorth(-12, 1.55), Vector3.new(14, 1.5, 0.05), NS.Back },
		{ onNorth(12, 1.55), Vector3.new(14, 1.5, 0.05), NS.Back },
		{ onSouth(-9, 1.55), Vector3.new(8, 1.5, 0.05), NS.Front },
		{ onSouth(9, 1.55), Vector3.new(8, 1.5, 0.05), NS.Front },
		{ onEast(-6, 1.55), Vector3.new(0.05, 1.5, 10), NS.Left },
	} do
		grime(decor, "scuff", cfg[1], cfg[2], cfg[3], 0.05)
	end
	-- Wallpaper peeling off along the top in a few places.
	for _, cfg in {
		{ onNorth(-25, H - 1.2), Vector3.new(7, 2.4, 0.05), NS.Back },
		{ onEast(15, H - 1.0), Vector3.new(0.05, 2, 6), NS.Left },
		{ onSouth(22, H - 1.3), Vector3.new(8, 2.6, 0.05), NS.Front },
		{ onWest(-17, H - 1.1), Vector3.new(0.05, 2.2, 6), NS.Right },
	} do
		grime(decor, "peel", cfg[1], cfg[2], cfg[3], 0)
	end
	-- Greasy smudges at hand height by the counter and the Ready panel.
	grime(decor, "wall_grime", onEast(5, 4), Vector3.new(0.05, 4, 7), NS.Left, 0.1)
	grime(decor, "wall_grime", onSouth(5, 4), Vector3.new(7, 4, 0.05), NS.Front, 0.15)
	-- A leak: stained ceiling tiles, a dark run down the wall, the carpet below.
	local leaks = { Vector2.new(-12, -6), Vector2.new(14, 8), Vector2.new(2, -14) }
	for i, at in leaks do
		local size = 3.6 + i * 0.4
		grime(decor, "water_stain", CFrame.new(o + Vector3.new(at.X, H - 0.03, at.Y)), Vector3.new(size, 0.04, size), NS.Bottom, 0)
		grime(decor, "floor_stain", CFrame.new(o + Vector3.new(at.X + 0.6, 0.025, at.Y - 0.4)) * CFrame.Angles(0, i * 1.3, 0), Vector3.new(size * 0.9, 0.04, size * 0.7), NS.Top, 0.1)
	end
	grime(decor, "water_stain", CFrame.new(o + Vector3.new(W / 2 - 2.5, H - 0.03, -16)), Vector3.new(4, 0.04, 4), NS.Bottom, 0)
	grime(decor, "drip_stain", onEast(-16, H - 3.2), Vector3.new(0.05, 6.4, 3.4), NS.Left, 0)
	-- Carpet worn into paths: spawn to the lift, the counter and the crew board.
	grime(decor, "wear_path", CFrame.new(o + Vector3.new(0, 0.02, 7)), Vector3.new(5.5, 0.04, 13), NS.Top, 0)
	grime(decor, "wear_path", CFrame.new(o + Vector3.new(13, 0.02, 0)) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(5, 0.04, 24), NS.Top, 0.1)
	grime(decor, "wear_path", CFrame.new(o + Vector3.new(0, 0.02, -11)), Vector3.new(6, 0.04, 18), NS.Top, 0.15)
	-- Spills by the lift and by the crate.
	grime(decor, "floor_stain", CFrame.new(o + Vector3.new(6.5, 0.025, 8.5)) * CFrame.Angles(0, 0.7, 0), Vector3.new(3.2, 0.04, 2.4), NS.Top, 0)
	grime(decor, "floor_stain", CFrame.new(o + Vector3.new(-25, 0.025, 8)) * CFrame.Angles(0, 2.1, 0), Vector3.new(2.6, 0.04, 2.2), NS.Top, 0.1)

	-- More crates by the supply crate, and boxes by the counter.
	part({ Name = "Crate", Size = Vector3.new(3, 2.6, 3), CFrame = CFrame.new(o + Vector3.new(-W / 2 + 4, 1.3, 17)) * CFrame.Angles(0, 0.12, 0), Color = Color3.fromRGB(120, 100, 64), Material = Enum.Material.WoodPlanks }, decor)
	part({ Name = "Crate", Size = Vector3.new(2.2, 1.9, 2.2), CFrame = CFrame.new(o + Vector3.new(-W / 2 + 4.2, 3.55, 16.8)) * CFrame.Angles(0, -0.3, 0), Color = Color3.fromRGB(112, 94, 60), Material = Enum.Material.WoodPlanks }, decor)
	part({ Name = "Crate", Size = Vector3.new(2.4, 2, 2.4), CFrame = CFrame.new(o + Vector3.new(-W / 2 + 8, 1, 18.5)) * CFrame.Angles(0, 0.5, 0), Color = Color3.fromRGB(126, 104, 66), Material = Enum.Material.WoodPlanks }, decor)
	part({ Name = "Box", Size = Vector3.new(2, 1.5, 1.6), CFrame = CFrame.new(o + Vector3.new(W / 2 - 3, 0.75, -10)) * CFrame.Angles(0, 0.2, 0), Color = Color3.fromRGB(150, 120, 80), Material = Enum.Material.Cardboard }, decor)
	part({ Name = "Box", Size = Vector3.new(1.6, 1.2, 1.4), CFrame = CFrame.new(o + Vector3.new(W / 2 - 3.2, 2.1, -10.1)) * CFrame.Angles(0, -0.25, 0), Color = Color3.fromRGB(160, 128, 84), Material = Enum.Material.Cardboard }, decor)

	-- A clipboard dropped on the floor, papers scattered round it.
	local board = CFrame.new(o + Vector3.new(9, 0.04, -5)) * CFrame.Angles(0, 0.4, 0)
	bit({ Name = "Clipboard", Size = Vector3.new(1.3, 0.06, 1.8), CFrame = board, Color = Color3.fromRGB(120, 90, 56), Material = Enum.Material.Wood }, decor)
	bit({ Name = "Paper", Size = Vector3.new(1.1, 0.02, 1.45), CFrame = board * CFrame.new(0, 0.04, 0.1), Color = PAPER, Material = Enum.Material.Plastic }, decor)
	bit({ Name = "Clip", Size = Vector3.new(0.55, 0.1, 0.22), CFrame = board * CFrame.new(0, 0.07, -0.78), Color = Color3.fromRGB(170, 168, 160), Material = Enum.Material.Metal }, decor)
	local rng = Random.new(1717)
	for _ = 1, 7 do
		bit({
			Name = "Paper",
			Size = Vector3.new(0.85, 0.02, 1.1),
			CFrame = CFrame.new(o + Vector3.new(6 + rng:NextNumber() * 7, 0.02 + rng:NextNumber() * 0.02, -9 + rng:NextNumber() * 7)) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
			Color = PAPER:Lerp(Color3.fromRGB(190, 176, 140), rng:NextNumber()),
			Material = Enum.Material.Plastic,
		}, decor)
	end

	-- Cables along the south wall to the lift, then up into the ceiling.
	for i, y in { 0.95, 1.15 } do
		local zc = D / 2 - 0.62 - i * 0.12
		bit({ Name = "Cable", Shape = Enum.PartType.Cylinder, Size = Vector3.new(W / 2 - 7, 0.16, 0.16), Position = o + Vector3.new(-W / 4 - 3.5, y, zc), Color = Color3.fromRGB(26, 25, 24), Material = Enum.Material.Rubber }, decor)
		bit({ Name = "Cable", Shape = Enum.PartType.Cylinder, Size = Vector3.new(H - y, 0.16, 0.16), CFrame = CFrame.new(o + Vector3.new(-7 + i * 0.2, (H + y) / 2, zc)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(26, 25, 24), Material = Enum.Material.Rubber }, decor)
	end
	for x = -W / 2 + 3, -8, 4 do
		bit({ Name = "CableClip", Size = Vector3.new(0.25, 0.5, 0.12), Position = o + Vector3.new(x, 1.05, D / 2 - 0.8), Color = Color3.fromRGB(150, 148, 140), Material = Enum.Material.Plastic }, decor)
	end
	bit({ Name = "JunctionBox", Size = Vector3.new(1.2, 1.4, 0.4), Position = o + Vector3.new(-7, 4, D / 2 - 0.75), Color = Color3.fromRGB(110, 108, 100), Material = Enum.Material.Metal }, decor)

	-- An EXIT-style sign hanging over the lift (it stutters, Realism.client).
	local exitBox = bit({ Name = "ExitSign", Size = Vector3.new(3.4, 1, 0.4), Position = o + Vector3.new(0, H - 1.1, D / 2 - 12.2), Color = Color3.fromRGB(34, 36, 32), Material = Enum.Material.Plastic }, decor)
	bit({ Name = "ExitHanger", Size = Vector3.new(0.08, 0.6, 0.08), Position = o + Vector3.new(-1.2, H - 0.3, D / 2 - 12.2), Color = Color3.fromRGB(60, 58, 52), Material = Enum.Material.Metal }, decor)
	bit({ Name = "ExitHanger", Size = Vector3.new(0.08, 0.6, 0.08), Position = o + Vector3.new(1.2, H - 0.3, D / 2 - 12.2), Color = Color3.fromRGB(60, 58, 52), Material = Enum.Material.Metal }, decor)
	local exitText = textOn(exitBox, Enum.NormalId.Front, "EXIT  ▼", Color3.fromRGB(120, 230, 140))
	exitText.Name = "ExitText"
	local exitGlow = Instance.new("PointLight")
	exitGlow.Color = Color3.fromRGB(120, 230, 140)
	exitGlow.Range = 7
	exitGlow.Brightness = 0.6
	exitGlow.Parent = exitBox
	CollectionService:AddTag(exitBox, "HubExitSign")

	-- A wall clock above the crew board that stopped at 3:17.
	clock(decor, CFrame.new(o + Vector3.new(0, 9.7, -D / 2 + 0.65)) * CFrame.Angles(0, math.rad(180), 0))

	-- Notes: the yellow sticky stays; a few more pinned round the room.
	local function westNote(z: number, y: number, w: number, h: number, text: string, colour: Color3?, pin: Color3?)
		note(decor, CFrame.new(o + Vector3.new(-W / 2 + 0.53, y, z)) * CFrame.Angles(0, math.rad(-90), 0), Vector2.new(w, h), text, colour, pin)
	end
	local function northNote(x: number, y: number, w: number, h: number, text: string, colour: Color3?, pin: Color3?, tilt: number?)
		note(decor, CFrame.new(o + Vector3.new(x, y, -D / 2 + 0.53)) * CFrame.Angles(0, math.rad(180), math.rad(tilt or 0)), Vector2.new(w, h), text, colour, pin)
	end
	local YELLOW = Color3.fromRGB(232, 210, 96)
	westNote(-6.8, 4.7, 0.8, 0.8, "don't go down short-handed", YELLOW, nil)
	northNote(-25.5, 5.6, 1.4, 1.8, "LIFT JAMS AT 3.\nkick the panel,\nthen wait", PAPER, Color3.fromRGB(170, 40, 30), 3)
	northNote(25.2, 5.2, 1.2, 1.5, "if the hum stops\nSTOP", PAPER, Color3.fromRGB(40, 90, 160), -4)
	northNote(26.8, 3.6, 0.8, 0.8, "who moved\nthe chair?", YELLOW, nil, 6)
	northNote(-27, 3.4, 1.1, 1.3, "quota is quota", Color3.fromRGB(214, 206, 180), Color3.fromRGB(60, 140, 70), -2)

	-- The duty roster beside the safehouse sign.
	local roster = bit({ Name = "Paper", Size = Vector3.new(2.3, 3, 0.03), CFrame = CFrame.new(o + Vector3.new(-W / 2 + 0.53, 6.1, 10.2)) * CFrame.Angles(0, math.rad(-90), 0), Color = PAPER, Material = Enum.Material.Plastic }, decor)
	local lines = { "<b>NIGHT SHIFT  -  DUTY ROSTER</b>", "" }
	local times = { "22:00", "23:30", "01:00", "02:30" }
	for c = 1, Config.CREW_COUNT do
		local name = Config.CREW_NAMES[c] or `CREW {c}`
		table.insert(lines, `{times[(c - 1) % #times + 1]}   {name}   descent`)
	end
	table.insert(lines, "")
	table.insert(lines, "03:17   <s>maintenance</s>")
	table.insert(lines, "")
	table.insert(lines, "<i>sign out at the lift. nobody stays down past quota.</i>")
	local rosterText = textOn(roster, Enum.NormalId.Front, table.concat(lines, "\n"), INK, nil, Enum.Font.Code)
	rosterText.RichText = true
	rosterText.TextXAlignment = Enum.TextXAlignment.Left
	rosterText.TextYAlignment = Enum.TextYAlignment.Top
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.07, 0)
	pad.PaddingTop = UDim.new(0.06, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.Parent = rosterText
	;(rosterText.Parent :: SurfaceGui).LightInfluence = 1
	bit({ Name = "Pin", Shape = Enum.PartType.Ball, Size = Vector3.new(0.16, 0.16, 0.16), Position = o + Vector3.new(-W / 2 + 0.6, 7.45, 10.2), Color = Color3.fromRGB(170, 40, 30), Material = Enum.Material.Plastic }, decor)
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
	part({ Name = "Floor", Size = Vector3.new(W, 1, D), Position = o + Vector3.new(0, -0.5, 0), Color = Color3.fromRGB(118, 100, 62), Material = Enum.Material.Carpet }, model)
	part({ Name = "Ceiling", Size = Vector3.new(W, 1, D), Position = o + Vector3.new(0, H + 0.5, 0), Color = Color3.fromRGB(200, 192, 170), Material = Enum.Material.Plaster }, model)
	local wallColour = Color3.fromRGB(196, 178, 112) -- yellowed (the colour until the wallpaper is installed)
	part({ Name = "WallN", Size = Vector3.new(W, H, 1), Position = o + Vector3.new(0, H / 2, -D / 2), Color = wallColour, Material = Enum.Material.Plaster }, model)
	part({ Name = "WallS", Size = Vector3.new(W, H, 1), Position = o + Vector3.new(0, H / 2, D / 2), Color = wallColour, Material = Enum.Material.Plaster }, model)
	part({ Name = "WallW", Size = Vector3.new(1, H, D), Position = o + Vector3.new(-W / 2, H / 2, 0), Color = wallColour, Material = Enum.Material.Plaster }, model)
	part({ Name = "WallE", Size = Vector3.new(1, H, D), Position = o + Vector3.new(W / 2, H / 2, 0), Color = wallColour, Material = Enum.Material.Plaster }, model)

	dress(model, o)

	-- Title on the west wall.
	local titleBoard = part({ Name = "Title", Size = Vector3.new(0.2, 3, 16), Position = o + Vector3.new(-W / 2 + 0.6, 7, 0), Color = Color3.fromRGB(28, 26, 20), Material = Enum.Material.Plastic }, model)
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
		local board = part({ Name = `Crew{c}Sign`, Size = Vector3.new(9, 4, 0.3), Position = o + Vector3.new(x, 5, -D / 2 + 0.8), Color = Color3.fromRGB(30, 28, 22), Material = Enum.Material.Plastic }, model)
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
	-- A worn concrete kerb round the plate.
	for _, k in { { Vector3.new(0, 0, 5.45), Vector3.new(11.4, 0.18, 0.9) }, { Vector3.new(0, 0, -5.45), Vector3.new(11.4, 0.18, 0.9) }, { Vector3.new(5.45, 0, 0), Vector3.new(0.9, 0.18, 10) }, { Vector3.new(-5.45, 0, 0), Vector3.new(0.9, 0.18, 10) } } do
		part({ Name = "LiftKerb", Size = k[2], Position = liftCentre + k[1] + Vector3.new(0, 0.09, 0), Color = Color3.fromRGB(140, 136, 126), Material = Enum.Material.Concrete }, model)
	end
	for _, corner in { Vector3.new(5, 0, 5), Vector3.new(-5, 0, 5), Vector3.new(5, 0, -5), Vector3.new(-5, 0, -5) } do
		-- Scuffed painted steel on a concrete footing.
		part({ Name = "Post", Size = Vector3.new(0.6, H, 0.6), Position = liftCentre + corner + Vector3.new(0, H / 2, 0), Color = Color3.fromRGB(128, 116, 74), Material = Enum.Material.Metal }, model)
		part({ Name = "PostFooting", Size = Vector3.new(1.4, 1.1, 1.4), Position = liftCentre + corner + Vector3.new(0, 0.55, 0), Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Concrete }, model)
	end
	local liftBoard = part({ Name = "LiftSign", Size = Vector3.new(10, 2.4, 0.3), Position = liftCentre + Vector3.new(0, 9, -5), Color = Color3.fromRGB(28, 26, 20), Material = Enum.Material.Plastic, CanCollide = false }, model)
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
