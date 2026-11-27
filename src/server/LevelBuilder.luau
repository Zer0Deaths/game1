--!strict
-- LevelBuilder: turns a LevelGen layout into parts in Workspace.
--
-- Two layers:
--   * Static (built once per level): floor, ceiling, ceiling grid, light
--     fittings, stains on the floor and ceiling. The Shift never rebuilds
--     these; it only switches lights on, off or to flicker (applyLights).
--   * Structure (rebuilt by every Shift): walls, skirting, wall details
--     (outlets, vents, water stains), doorways, pillars and the props that
--     dress each set piece (offices, storage, atriums).
--
-- Every detail is placed from a hash of its position and the level seed,
-- never from a running random number. So anything a player is standing
-- next to during a Shift is rebuilt exactly as it was.
--
-- Every part gets a PBR surface (Shared.Surfaces): the level type's
-- wallpaper/carpet/ceiling sets on the big surfaces, and a set matched to
-- each prop's material (painted metal, wood, fabric...). Until the
-- textures are uploaded, built-in materials stand in. No SmoothPlastic.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local LevelGen = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LevelGen"))
local Surfaces = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Surfaces"))
local Grime = require(script.Parent:WaitForChild("Grime"))
local Meshes = require(script.Parent:WaitForChild("Meshes"))

local LevelBuilder = {}

-- Sizes in studs. A Roblox character is about 5 studs tall.
LevelBuilder.CELL = 20 -- width of one grid cell
LevelBuilder.HEIGHT = 11 -- floor to ceiling, low on purpose so it feels cramped
LevelBuilder.THICK = 1 -- wall thickness

local COLORS = {
	wall = Color3.fromRGB(201, 181, 104), -- stained yellow wallpaper
	skirting = Color3.fromRGB(112, 94, 54), -- scuffed brown skirting board
	carpet = Color3.fromRGB(128, 110, 62), -- damp mustard carpet
	ceiling = Color3.fromRGB(206, 201, 178), -- yellowed ceiling tiles
	grid = Color3.fromRGB(150, 146, 128), -- metal T-bar ceiling grid
	housing = Color3.fromRGB(186, 184, 174), -- light fitting frame
	lightOn = Color3.fromRGB(252, 236, 186), -- warm yellow fluorescent
	lightDead = Color3.fromRGB(64, 62, 56),
	pillar = Color3.fromRGB(190, 170, 96),
	stain = Color3.fromRGB(92, 70, 30), -- water damage
}

-- Built-in Roblox materials (no uploads needed).
local MATERIALS = {
	wall = Enum.Material.Plaster,
	carpet = Enum.Material.Carpet,
	ceiling = Enum.Material.Plaster,
	trim = Enum.Material.Metal, -- skirting, ceiling grid: painted metal
}

-- MaterialVariant names per surface for the current level type ("" = none).
local VARIANTS = { wall = "", carpet = "", ceiling = "" }

-- Which level type is being built ("carpet", "ward", "plant"): picks the
-- props (office clutter, medical kit, pipes and valves) and the grime.
local KIND = "carpet"

-- Each level keeps the theme it was built with, so a Shift in one crew's
-- level rebuilds with its own look even if another crew built since.
local themes: { [Instance]: { colors: { [string]: Color3 }, materials: { [string]: Enum.Material }, variants: { [string]: string }, kind: string } } = {} -- strong: weak Instance keys can vanish while the level still exists

local DEFAULT_COLORS = table.clone(COLORS)
local DEFAULT_MATERIALS = table.clone(MATERIALS)

-- Level types (LevelTypes.luau) swap colours, materials and texture
-- variants before a build.
function LevelBuilder.setTheme(colours: { [string]: Color3 }, materials: { [string]: string }, variants: { [string]: string }?, kind: string?)
	KIND = kind or "carpet"
	for k, v in DEFAULT_COLORS do
		COLORS[k] = colours[k] or v
	end
	for k, v in DEFAULT_MATERIALS do
		local name = materials[k]
		MATERIALS[k] = if name then (Enum.Material :: any)[name] else v
	end
	for k in VARIANTS do
		VARIANTS[k] = if variants then variants[k] or "" else ""
	end
end

-- Puts a texture variant on a part when one is set up for this surface.
local function surface(p: BasePart, kind: string)
	local name = VARIANTS[kind]
	if name and name ~= "" and Surfaces.has(name) then
		-- Keep the patchy per-wall shading as a light grey over the texture.
		local c = p.Color
		local base = COLORS[kind] or c
		local shade = math.clamp((c.R + c.G + c.B) / math.max(0.01, base.R + base.G + base.B), 0.82, 1)
		Surfaces.apply(p, name)
		p.Color = Color3.new(shade, shade, shade)
	elseif name and name ~= "" then
		Surfaces.texture(p, name) -- colour map on the big faces until the variants are installed
	end
end

-- Each crew's level is built at its own origin (see Sublevels). Every part
-- is positioned in level space and shifted by this while it's created.
local ORIGIN = Vector3.zero

local function makePart(props: { [string]: any }, parent: Instance): Part
	if props.Position then
		props.Position += ORIGIN
	end
	if props.CFrame then
		props.CFrame += ORIGIN
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	Surfaces.auto(p) -- PBR set by material; never SmoothPlastic
	p.Parent = parent
	return p
end

-- Small decorative part: no collisions, no shadows, ignored by raycasts.
local function detail(props: { [string]: any }, parent: Instance): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return makePart(props, parent)
end

-- Solid prop (desks, shelves): players bump into it, but it casts no
-- shadow and the Tenant's line of sight ignores it.
local function prop(props: { [string]: any }, parent: Instance): Part
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return makePart(props, parent)
end

-- A grime decal (Grime.luau) on an invisible holder, in level space.
-- Returns false if that decal isn't uploaded (callers fall back).
local function grime(parent: Instance, key: string, cf: CFrame, size: Vector3, face: Enum.NormalId, transparency: number?): boolean
	return Grime.patch(function(props)
		return detail(props, parent)
	end, key, cf, size, face, transparency) ~= nil
end

-- Deterministic 0..1 from a position and the seed.
local function hash(a: number, b: number, c: number, seed: number): number
	local h = math.sin(a * 12.9898 + b * 78.233 + c * 37.719 + seed * 0.0137) * 43758.5453
	return h - math.floor(h)
end

-- Is this position inside the level built at `origin` (not the safehouse,
-- not another crew's level)?
function LevelBuilder.inLevel(layout: LevelGen.Layout, pos: Vector3, origin: Vector3?): boolean
	local s = LevelBuilder.CELL
	local p = pos - (origin or Vector3.zero)
	return p.X >= 0 and p.Z >= 0 and p.X <= layout.width * s and p.Z <= layout.depth * s and p.Y > -20 and p.Y < 40
end

-- Position of the middle of a cell, at floor height. Without an origin
-- it's in level space; with one it's in the world.
function LevelBuilder.cellCenter(x: number, z: number, origin: Vector3?): Vector3
	local s = LevelBuilder.CELL
	return Vector3.new((x - 0.5) * s, 0, (z - 0.5) * s) + (origin or Vector3.zero)
end

-- The cell a world position is in (clamped to the grid).
function LevelBuilder.cellOf(layout: LevelGen.Layout, pos: Vector3, origin: Vector3?): (number, number)
	local p = pos - (origin or Vector3.zero)
	local s = LevelBuilder.CELL
	return math.clamp(math.floor(p.X / s) + 1, 1, layout.width), math.clamp(math.floor(p.Z / s) + 1, 1, layout.depth)
end

-- PROPS ------------------------------------------------------------------------

local WOOD = Color3.fromRGB(150, 120, 82)
local GREY_METAL = Color3.fromRGB(120, 122, 120)
local DARK = Color3.fromRGB(34, 34, 36)
local CARDBOARD = Color3.fromRGB(168, 130, 84)
local PAPER = Color3.fromRGB(226, 222, 206)
local FABRIC_BLUE = Color3.fromRGB(70, 82, 96)

-- Everything below is built in a cell's local frame: origin at the cell
-- centre on the floor, rotated by `yaw`.
local function chair(parent: Instance, at: CFrame, tipped: boolean)
	local base = if tipped then at * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90)) else at
	local seat = prop({ Name = "ChairSeat", Size = Vector3.new(1.7, 0.3, 1.7), CFrame = base * CFrame.new(0, 1.6, 0), Color = FABRIC_BLUE, Material = Enum.Material.Fabric }, parent)
	Meshes.dress("chair", base + ORIGIN, parent, {
		seat,
		prop({ Name = "ChairBack", Size = Vector3.new(1.7, 1.9, 0.25), CFrame = base * CFrame.new(0, 2.7, 0.8) * CFrame.Angles(math.rad(-8), 0, 0), Color = FABRIC_BLUE, Material = Enum.Material.Fabric }, parent),
		detail({ Name = "ChairPost", Size = Vector3.new(0.22, 1.4, 0.22), CFrame = base * CFrame.new(0, 0.8, 0), Color = DARK, Material = Enum.Material.Metal }, parent),
		detail({ Name = "ChairFoot", Size = Vector3.new(1.5, 0.15, 1.5), CFrame = base * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(45), 0), Color = DARK, Material = Enum.Material.Metal }, parent),
	}, { copy = { Upholstery = seat } })
end

local function desk(parent: Instance, at: CFrame, h: (number) -> number)
	local top = prop({ Name = "DeskTop", Size = Vector3.new(5.2, 0.25, 2.6), CFrame = at * CFrame.new(0, 2.6, 0), Color = WOOD, Material = Enum.Material.WoodPlanks }, parent)
	local parts = { top }
	for _, side in { -1, 1 } do
		table.insert(parts, prop({ Name = "DeskSide", Size = Vector3.new(0.2, 2.5, 2.5), CFrame = at * CFrame.new(side * 2.45, 1.25, 0), Color = GREY_METAL, Material = Enum.Material.Metal }, parent))
	end
	table.insert(parts, detail({ Name = "DeskPanel", Size = Vector3.new(4.7, 1.4, 0.12), CFrame = at * CFrame.new(0, 1.7, -1.15), Color = GREY_METAL, Material = Enum.Material.Metal }, parent))
	Meshes.dress("desk", at + ORIGIN, parent, parts, { copy = { DeskTop = top, DeskFrame = parts[2] } })
	if h(1) < 0.75 then
		-- An old CRT-ish monitor, left on its stand or knocked over.
		local fallen = h(2) < 0.2
		local m = if fallen then at * CFrame.new(0.4, 2.9, -0.2) * CFrame.Angles(math.rad(-90), 0, 0) else at * CFrame.new(0.4, 3.55, -0.6)
		Meshes.dress("crt_monitor", m + ORIGIN, parent, {
			detail({ Name = "Monitor", Size = Vector3.new(1.7, 1.25, 1.1), CFrame = m, Color = Color3.fromRGB(196, 190, 172), Material = Enum.Material.Plastic }, parent),
			detail({ Name = "Screen", Size = Vector3.new(1.4, 0.95, 0.05), CFrame = m * CFrame.new(0, 0, 0.56), Color = Color3.fromRGB(24, 28, 26), Material = Enum.Material.Glass, Reflectance = 0.15 }, parent),
		})
	end
	if h(3) < 0.6 then
		local k = at * CFrame.new(0.4, 2.73, 0.5) * CFrame.Angles(0, math.rad((h(4) - 0.5) * 30), 0)
		Meshes.dress("keyboard", k + ORIGIN, parent, {
			detail({ Name = "Keyboard", Size = Vector3.new(1.5, 0.08, 0.5), CFrame = k * CFrame.new(0, 0.04, 0), Color = Color3.fromRGB(186, 180, 162), Material = Enum.Material.Plastic }, parent),
		})
	end
	-- Paper left lying around (the Blender scatter of sheets, where the first fell).
	local sheets = {}
	for i = 1, math.floor(h(5) * 4) do
		table.insert(sheets, detail({ Name = "Paper", Size = Vector3.new(0.85, 0.02, 1.1), CFrame = at * CFrame.new((h(10 + i) - 0.5) * 7, 0.02, (h(20 + i) - 0.5) * 6) * CFrame.Angles(0, h(30 + i) * 6.28, 0), Color = PAPER, Material = Enum.Material.Plastic }, parent))
	end
	if #sheets > 0 then
		-- The papers model is built face down (Safehouse flips it the same way).
		local first = at * CFrame.new((h(11) - 0.5) * 7, 0.05, (h(21) - 0.5) * 6)
		Meshes.dress("papers", CFrame.new(first.Position + ORIGIN) * CFrame.Angles(math.pi, h(31) * 6.28, 0), parent, sheets)
	end
	chair(parent, at * CFrame.new((h(6) - 0.5) * 1.5, 0, 2.2 + h(7)) * CFrame.Angles(0, (h(8) - 0.5) * 1.6, 0), h(9) < 0.15)
end

local function filingCabinet(parent: Instance, at: CFrame)
	local body = prop({ Name = "Cabinet", Size = Vector3.new(1.8, 4.4, 2.2), CFrame = at * CFrame.new(0, 2.2, 0), Color = Color3.fromRGB(140, 138, 126), Material = Enum.Material.Metal }, parent)
	local parts = { body }
	for i = 0, 3 do
		table.insert(parts, detail({ Name = "DrawerLine", Size = Vector3.new(1.6, 0.05, 0.04), CFrame = at * CFrame.new(0, 0.6 + i * 1.05, -1.11), Color = DARK, Material = Enum.Material.Metal }, parent))
		table.insert(parts, detail({ Name = "Handle", Size = Vector3.new(0.5, 0.1, 0.1), CFrame = at * CFrame.new(0, 0.95 + i * 1.05, -1.14), Color = Color3.fromRGB(180, 178, 170), Material = Enum.Material.Metal }, parent))
	end
	Meshes.dress("filing_cabinet", at + ORIGIN, parent, parts)
end

-- A box on a shelf. With the Blender boxes uploaded it's an archive box or
-- a packing carton (whichever fits the gap), at the model's own size, so
-- the box you bump into is the box you see.
local function box(parent: Instance, cf: CFrame, size: Vector3)
	local name = if size.X >= 1.8 then "carton" else "archive_box"
	local model = Meshes.size(name)
	local scale = 1
	if Meshes.has(name) and model then
		scale = math.min(1, size.X / model.X)
		size = model * scale
	end
	local parts = {
		prop({ Name = "Box", Size = size, CFrame = cf * CFrame.new(0, size.Y / 2, 0), Color = CARDBOARD, Material = Enum.Material.Cardboard }, parent),
		detail({ Name = "Tape", Size = Vector3.new(size.X + 0.02, 0.02, 0.35), CFrame = cf * CFrame.new(0, size.Y + 0.01, 0), Color = Color3.fromRGB(190, 170, 120), Material = Enum.Material.Plastic }, parent),
	}
	Meshes.dress(name, cf + ORIGIN, parent, parts, { scale = scale })
end

-- Gaps left on shelves while building, where loot can sit (world CFrame
-- on the shelf's top surface, and how wide the gap is). Collected per
-- build; see LevelBuilder.shelfSlots.
local SLOTS: { { cf: CFrame, width: number } } = {}

local function shelving(parent: Instance, at: CFrame, h: (number) -> number)
	local W, Dp, Ht = 8, 2.4, 7.4
	local rack = {}
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			table.insert(rack, prop({ Name = "Upright", Size = Vector3.new(0.25, Ht, 0.25), CFrame = at * CFrame.new(sx * W / 2, Ht / 2, sz * Dp / 2), Color = Color3.fromRGB(70, 96, 140), Material = Enum.Material.Metal }, parent))
		end
	end
	for level = 0, 3 do
		table.insert(rack, prop({ Name = "Shelf", Size = Vector3.new(W, 0.15, Dp), CFrame = at * CFrame.new(0, 0.4 + level * 2.2, 0), Color = GREY_METAL, Material = Enum.Material.DiamondPlate }, parent))
	end
	Meshes.dress("shelf_rack", at + ORIGIN, parent, rack)
	for level = 0, 3 do
		local y = 0.4 + level * 2.2
		-- Boxes on the shelf (not all of them full).
		local x = -W / 2 + 0.3
		local i = 0
		while x < W / 2 - 1.2 do
			i += 1
			local bw = 1.2 + h(level * 10 + i) * 1.4
			if level > 0 and h(level * 10 + i + 50) < 0.7 and x + bw < W / 2 then -- none on the bottom shelf, right by the floor
				local bh = math.min(1.9, 0.8 + h(level * 10 + i + 90) * 1.2)
				box(parent, at * CFrame.new(x + bw / 2, y + 0.08, (h(i + 7) - 0.5) * 0.3) * CFrame.Angles(0, (h(i + 3) - 0.5) * 0.3, 0), Vector3.new(bw, bh, Dp - 0.5))
			elseif level < 3 and x + bw < W / 2 then
				-- An empty gap at reachable height: loot can be left here.
				table.insert(SLOTS, { cf = (at * CFrame.new(x + bw / 2, y + 0.075, 0)) + ORIGIN, width = bw })
			end
			x += bw + 0.15
		end
	end
end

local function puddle(parent: Instance, at: CFrame, size: number)
	local p = detail({
		Name = "Puddle",
		Size = Vector3.new(0.03, size, size * 0.7),
		CFrame = at * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(70, 66, 50),
		Material = Enum.Material.Glass,
		Transparency = 0.45,
		Reflectance = 0.25,
	}, parent)
	p.Shape = Enum.PartType.Cylinder
end


-- Office clutter (The Carpet).
local function waterCooler(parent: Instance, at: CFrame)
	local body = prop({ Name = "CoolerBody", Size = Vector3.new(1.4, 3.2, 1.4), CFrame = at * CFrame.new(0, 1.6, 0), Color = Color3.fromRGB(206, 200, 184), Material = Enum.Material.Plastic }, parent)
	local bottle = detail({ Name = "CoolerBottle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 1.15, 1.15), CFrame = at * CFrame.new(0, 4.0, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(150, 176, 186), Material = Enum.Material.Glass, Transparency = 0.45 }, parent)
	bottle.Reflectance = 0.1
	local tap = detail({ Name = "CoolerTap", Size = Vector3.new(0.2, 0.25, 0.3), CFrame = at * CFrame.new(0.3, 2.4, -0.78), Color = Color3.fromRGB(60, 90, 170), Material = Enum.Material.Plastic }, parent)
	Meshes.dress("water_cooler", at + ORIGIN, parent, { body, bottle, tap })
end

local function wastebin(parent: Instance, at: CFrame, h: (number) -> number)
	local tipped = h(70) < 0.25
	local cf = if tipped then at * CFrame.new(0, 0.45, 0) * CFrame.Angles(math.rad(90), 0, 0) else at * CFrame.new(0, 0.6, 0)
	local parts = { detail({ Name = "Bin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 0.9, 0.9), CFrame = cf * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(70, 72, 70), Material = Enum.Material.Metal }, parent) }
	for i = 1, 3 do
		table.insert(parts, detail({ Name = "Paper", Size = Vector3.new(0.4, 0.35, 0.4), CFrame = (if tipped then at * CFrame.new((i - 2) * 0.5, 0.18, -0.9 - h(70 + i)) else at * CFrame.new(0, 1.15, 0)) * CFrame.Angles(h(73 + i) * 3, h(76 + i) * 3, 0), Color = PAPER, Material = Enum.Material.Plastic }, parent))
	end
	Meshes.dress(if tipped then "wastebin_tipped" else "wastebin", at + ORIGIN, parent, parts)
end

local function binders(parent: Instance, at: CFrame, h: (number) -> number)
	local colours = { Color3.fromRGB(120, 40, 36), Color3.fromRGB(40, 60, 100), Color3.fromRGB(60, 80, 50), Color3.fromRGB(60, 58, 54) }
	local parts = {}
	for i = 0, math.floor(h(80) * 4) + 1 do
		table.insert(parts, detail({ Name = "Binder", Size = Vector3.new(0.35, 1.3, 1.0), CFrame = at * CFrame.new(i * 0.38, 0.65, 0) * CFrame.Angles(0, 0, if i == 0 and h(81) < 0.5 then math.rad(20) else 0), Color = colours[(i % #colours) + 1], Material = Enum.Material.Plastic }, parent))
	end
	Meshes.dress("binders", at + ORIGIN, parent, parts)
end

local function fallenTile(parent: Instance, at: CFrame, h: (number) -> number)
	local parts = { detail({ Name = "FallenTile", Size = Vector3.new(4.6, 0.25, 4.6), CFrame = at * CFrame.new(0, 0.35, 0) * CFrame.Angles(math.rad(8 * (h(85) - 0.5)), h(86) * 6, math.rad(10)), Color = Color3.fromRGB(198, 190, 166), Material = Enum.Material.Plaster }, parent) }
	for i = 1, 4 do
		table.insert(parts, detail({ Name = "TileChunk", Size = Vector3.new(0.5 + h(86 + i) * 0.8, 0.2, 0.4 + h(90 + i) * 0.6), CFrame = at * CFrame.new((h(94 + i) - 0.5) * 6, 0.1, (h(98 + i) - 0.5) * 6) * CFrame.Angles(0, h(102 + i) * 6, 0), Color = Color3.fromRGB(198, 190, 166), Material = Enum.Material.Plaster }, parent))
	end
	Meshes.dress("fallen_tile", at * CFrame.Angles(0, h(86) * 6, 0) + ORIGIN, parent, parts)
end

-- Medical kit (The Ward).
local CHROME = Color3.fromRGB(170, 172, 170)
local SHEET = Color3.fromRGB(196, 204, 198)

local function gurney(parent: Instance, at: CFrame, h: (number) -> number)
	local parts = {
		prop({ Name = "GurneyFrame", Size = Vector3.new(2.6, 0.25, 6.4), CFrame = at * CFrame.new(0, 2.3, 0), Color = CHROME, Material = Enum.Material.Metal }, parent),
		detail({ Name = "Mattress", Size = Vector3.new(2.4, 0.4, 6.1), CFrame = at * CFrame.new(0, 2.6, 0), Color = Color3.fromRGB(110, 140, 130), Material = Enum.Material.Rubber }, parent),
		-- A rumpled sheet half pulled off.
		detail({ Name = "Sheet", Size = Vector3.new(2.6, 0.06, 4.2), CFrame = at * CFrame.new(0.2, 2.84, 0.8) * CFrame.Angles(0, 0, math.rad(4 + h(110) * 8)), Color = SHEET, Material = Enum.Material.Fabric }, parent),
		detail({ Name = "Sheet", Size = Vector3.new(0.06, 1.6, 3.6), CFrame = at * CFrame.new(1.4, 2.0, 0.9) * CFrame.Angles(0, 0, math.rad(-6)), Color = SHEET, Material = Enum.Material.Fabric }, parent),
	}
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			table.insert(parts, detail({ Name = "GurneyLeg", Size = Vector3.new(0.15, 2.1, 0.15), CFrame = at * CFrame.new(sx * 1.1, 1.15, sz * 2.9), Color = CHROME, Material = Enum.Material.Metal }, parent))
			table.insert(parts, detail({ Name = "Caster", Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.35, 0.35), CFrame = at * CFrame.new(sx * 1.1, 0.18, sz * 2.9), Color = DARK, Material = Enum.Material.Rubber }, parent))
		end
		table.insert(parts, detail({ Name = "Rail", Size = Vector3.new(0.1, 0.1, 3.6), CFrame = at * CFrame.new(sx * 1.3, 3.0, -1.0), Color = CHROME, Material = Enum.Material.Metal }, parent))
	end
	Meshes.dress("gurney", at + ORIGIN, parent, parts)
end

local function ivStand(parent: Instance, at: CFrame, h: (number) -> number)
	local tilt = if h(112) < 0.2 then math.rad(70) else 0
	local base = at * CFrame.Angles(0, 0, tilt) * CFrame.new(0, if tilt ~= 0 then 0.3 else 0, 0)
	local bag = detail({ Name = "IVBag", Size = Vector3.new(0.6, 0.9, 0.2), CFrame = base * CFrame.new(0.45, 5.5, 0), Color = Color3.fromRGB(210, 214, 200), Material = Enum.Material.Glass, Transparency = 0.35 }, parent)
	bag.Reflectance = 0.05
	Meshes.dress("iv_stand", base + ORIGIN, parent, {
		detail({ Name = "IVPole", Size = Vector3.new(0.12, 6.2, 0.12), CFrame = base * CFrame.new(0, 3.1, 0), Color = CHROME, Material = Enum.Material.Metal }, parent),
		detail({ Name = "IVFoot", Size = Vector3.new(1.6, 0.12, 0.2), CFrame = base * CFrame.new(0, 0.15, 0), Color = CHROME, Material = Enum.Material.Metal }, parent),
		detail({ Name = "IVFoot", Size = Vector3.new(0.2, 0.12, 1.6), CFrame = base * CFrame.new(0, 0.15, 0), Color = CHROME, Material = Enum.Material.Metal }, parent),
		detail({ Name = "IVHook", Size = Vector3.new(1.0, 0.08, 0.08), CFrame = base * CFrame.new(0, 6.1, 0), Color = CHROME, Material = Enum.Material.Metal }, parent),
		bag,
	})
end

local function wheelchair(parent: Instance, at: CFrame, h: (number) -> number)
	local parts = {
		prop({ Name = "ChairSeat", Size = Vector3.new(1.9, 0.25, 1.8), CFrame = at * CFrame.new(0, 2.0, 0), Color = Color3.fromRGB(40, 42, 44), Material = Enum.Material.Fabric }, parent),
		detail({ Name = "ChairBack", Size = Vector3.new(1.9, 1.8, 0.15), CFrame = at * CFrame.new(0, 3.0, 0.9) * CFrame.Angles(math.rad(-10), 0, 0), Color = Color3.fromRGB(40, 42, 44), Material = Enum.Material.Fabric }, parent),
	}
	for _, sx in { -1, 1 } do
		table.insert(parts, detail({ Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.18, 2.6, 2.6), CFrame = at * CFrame.new(sx * 1.15, 1.3, 0.3), Color = DARK, Material = Enum.Material.Rubber }, parent))
		table.insert(parts, detail({ Name = "Handle", Size = Vector3.new(0.12, 0.12, 0.6), CFrame = at * CFrame.new(sx * 0.85, 3.9, 1.2), Color = CHROME, Material = Enum.Material.Metal }, parent))
		table.insert(parts, detail({ Name = "Caster", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4), CFrame = at * CFrame.new(sx * 0.8, 0.2, -1.0), Color = DARK, Material = Enum.Material.Rubber }, parent))
	end
	Meshes.dress("wheelchair", at + ORIGIN, parent, parts)
end

local function curtainRail(parent: Instance, at: CFrame, h: (number) -> number, height: number)
	local parts = { detail({ Name = "CurtainRail", Size = Vector3.new(8, 0.1, 0.1), CFrame = at * CFrame.new(0, height - 0.6, 0), Color = CHROME, Material = Enum.Material.Metal }, parent) }
	local x = -3.8
	local i = 0
	while x < 3.8 do
		i += 1
		local w = 0.9 + h(120 + i) * 0.5
		if h(130 + i) < 0.78 then
			-- Pleated panels, some pushed aside, a few hanging torn short.
			local len = if h(140 + i) < 0.15 then 3 + h(150 + i) * 2 else height - 1.6
			table.insert(parts, detail({ Name = "Curtain", Size = Vector3.new(w, len, 0.06), CFrame = at * CFrame.new(x + w / 2, height - 0.65 - len / 2, (i % 2) * 0.12) * CFrame.Angles(0, (h(160 + i) - 0.5) * 0.5, 0), Color = Color3.fromRGB(150, 176, 168), Material = Enum.Material.Fabric }, parent))
		end
		x += w
	end
	-- The Blender curtains are drawn for the 11-stud ceilings; turned
	-- round at random so they aren't all bunched at the same end.
	if height == 11 then
		Meshes.dress("curtain_rail", at * CFrame.Angles(0, if h(119) < 0.5 then math.pi else 0, 0) + ORIGIN, parent, parts)
	end
end

local function medCabinet(parent: Instance, at: CFrame)
	Meshes.dress("med_cabinet", at + ORIGIN, parent, {
		prop({ Name = "MedCabinet", Size = Vector3.new(3, 5.4, 1.4), CFrame = at * CFrame.new(0, 2.7, 0), Color = Color3.fromRGB(210, 212, 204), Material = Enum.Material.Metal }, parent),
		detail({ Name = "CabinetGlass", Size = Vector3.new(2.6, 2.4, 0.05), CFrame = at * CFrame.new(0, 3.8, -0.72), Color = Color3.fromRGB(150, 170, 170), Material = Enum.Material.Glass, Transparency = 0.5 }, parent),
		detail({ Name = "SharpsBin", Size = Vector3.new(0.8, 0.9, 0.6), CFrame = at * CFrame.new(1.0, 5.85, 0), Color = Color3.fromRGB(200, 170, 40), Material = Enum.Material.Plastic }, parent),
	})
end

-- Plant machinery (The Plant Room).
local PIPE = Color3.fromRGB(96, 92, 84)
local VALVE_RED = Color3.fromRGB(128, 44, 34)

local function drum(parent: Instance, at: CFrame, h: (number) -> number)
	local tipped = h(170) < 0.2
	local cf = if tipped then at * CFrame.new(0, 1.1, 0) * CFrame.Angles(0, h(171) * 6, 0) else at * CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90))
	local colours = { Color3.fromRGB(70, 84, 70), Color3.fromRGB(110, 60, 40), Color3.fromRGB(60, 64, 80) }
	local body = prop({ Name = "Drum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(if tipped then 3.4 else 3.4, 2.2, 2.2), CFrame = cf, Color = colours[math.floor(h(172) * 3) + 1], Material = Enum.Material.CorrodedMetal }, parent)
	-- The Blender drum is modelled standing up (axis Y); a Cylinder part's
	-- axis is X, so turn the model's Y onto the part's X and drop it back
	-- by half its height (it's modelled from the floor up).
	Meshes.dress("oil_drum", cf * CFrame.Angles(0, 0, math.rad(-90)) * CFrame.new(0, -1.7, 0) + ORIGIN, parent, { body }, { copy = { Drum = body } })
end

local function boiler(parent: Instance, at: CFrame, h: (number) -> number, height: number)
	local parts = {
		prop({ Name = "Tank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(height - 2.5, 5, 5), CFrame = at * CFrame.new(0, (height - 2.5) / 2 + 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(104, 100, 90), Material = Enum.Material.Metal }, parent),
		prop({ Name = "TankPlinth", Size = Vector3.new(5.6, 0.5, 5.6), CFrame = at * CFrame.new(0, 0.25, 0), Color = Color3.fromRGB(120, 116, 108), Material = Enum.Material.Concrete }, parent),
		detail({ Name = "Pipe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, 0.6, 0.6), CFrame = at * CFrame.new(0, height - 1.0, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = PIPE, Material = Enum.Material.Metal }, parent),
		-- Gauge on the side.
		detail({ Name = "Gauge", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 0.9, 0.9), CFrame = at * CFrame.new(0, 4, -2.55) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(220, 214, 196), Material = Enum.Material.Plastic }, parent),
	}
	if height == 11 then -- the Blender boiler's flue is cut for the 11-stud ceilings
		Meshes.dress("boiler", at + ORIGIN, parent, parts)
	end
end

local function pump(parent: Instance, at: CFrame)
	Meshes.dress("pump", at + ORIGIN, parent, {
		prop({ Name = "PumpBase", Size = Vector3.new(4.4, 0.6, 2.4), CFrame = at * CFrame.new(0, 0.3, 0), Color = Color3.fromRGB(70, 70, 66), Material = Enum.Material.Metal }, parent),
		prop({ Name = "Motor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 1.7, 1.7), CFrame = at * CFrame.new(-0.8, 1.45, 0), Color = Color3.fromRGB(60, 90, 80), Material = Enum.Material.Metal }, parent),
		prop({ Name = "PumpHead", Size = Vector3.new(1.4, 1.6, 1.6), CFrame = at * CFrame.new(1.3, 1.4, 0), Color = Color3.fromRGB(90, 70, 50), Material = Enum.Material.CorrodedMetal }, parent),
		detail({ Name = "Pipe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 0.5, 0.5), CFrame = at * CFrame.new(1.3, 3.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = PIPE, Material = Enum.Material.Metal }, parent),
	})
end

-- A valve wheel facing out of a wall (frame: -Z out of the wall).
local function valve(parent: Instance, cf: CFrame): { BasePart }
	return {
		detail({ Name = "ValveWheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 1.3, 1.3), CFrame = cf * CFrame.Angles(0, math.rad(90), 0), Color = VALVE_RED, Material = Enum.Material.Metal }, parent),
		detail({ Name = "ValveStem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.25, 0.25), CFrame = cf * CFrame.new(0, 0, 0.25) * CFrame.Angles(0, math.rad(90), 0), Color = PIPE, Material = Enum.Material.Metal }, parent),
	}
end

-- The Ward's set pieces: exam bays, parked gurneys, abandoned wheelchairs.
local function dressWard(parent: Instance, kind: string, room: LevelGen.Room, c: Vector3, at: CFrame, h: (number) -> number)
	local H = LevelBuilder.HEIGHT
	if kind == "office" then
		-- An exam bay: a gurney behind a half-drawn curtain, a cabinet.
		gurney(parent, at * CFrame.new((h(41) - 0.5) * 3, 0, 1), h)
		curtainRail(parent, at * CFrame.new(0, 0, -3.5), h, H)
		if h(43) < 0.6 then
			medCabinet(parent, at * CFrame.new(7.5, 0, (h(44) - 0.5) * 8) * CFrame.Angles(0, math.rad(90), 0))
		end
		if h(45) < 0.5 then
			ivStand(parent, at * CFrame.new(-2.2, 0, 2.5), h)
		end
	elseif kind == "storage" then
		local alongX = room.w >= room.d
		shelving(parent, CFrame.new(c) * CFrame.Angles(0, if alongX then 0 else math.rad(90), 0) * CFrame.new(0, 0, -4), h)
	elseif kind == "atrium" or kind == "room" then
		local roll = h(52)
		local spot = at * CFrame.new((h(53) - 0.5) * 10, 0, (h(54) - 0.5) * 10)
		if roll < 0.1 then
			gurney(parent, spot, h)
		elseif roll < 0.2 then
			wheelchair(parent, spot, h)
		elseif roll < 0.3 then
			ivStand(parent, spot, h)
		elseif roll < 0.36 then
			puddle(parent, CFrame.new(c + Vector3.new((h(59) - 0.5) * 10, 0, (h(60) - 0.5) * 10)), 3 + h(61) * 4)
		end
	elseif kind == "hall" then
		if h(62) < 0.1 then
			gurney(parent, at * CFrame.new(6.5, 0, (h(63) - 0.5) * 10), h) -- parked against the wall
		end
	else
		local roll = h(65)
		if roll < 0.03 then
			ivStand(parent, at * CFrame.new(6.5, 0, (h(66) - 0.5) * 10), h)
		elseif roll < 0.045 then
			wheelchair(parent, at * CFrame.new(5.5, 0, (h(67) - 0.5) * 10) * CFrame.Angles(0, h(68) * 6, 0), h)
		end
	end
end

-- The Plant Room's set pieces: boilers, pumps, drums, racking.
local function dressPlant(parent: Instance, kind: string, room: LevelGen.Room, c: Vector3, at: CFrame, h: (number) -> number)
	local H = LevelBuilder.HEIGHT
	if kind == "office" then
		-- The control room: a desk and a cabinet of logbooks.
		desk(parent, at * CFrame.new((h(41) - 0.5) * 4, 0, (h(42) - 0.5) * 4), h)
		filingCabinet(parent, at * CFrame.new(7, 0, (h(44) - 0.5) * 10) * CFrame.Angles(0, math.rad(90), 0))
	elseif kind == "storage" then
		local alongX = room.w >= room.d
		shelving(parent, CFrame.new(c) * CFrame.Angles(0, if alongX then 0 else math.rad(90), 0) * CFrame.new(0, 0, -4), h)
		if h(45) < 0.45 then
			drum(parent, at * CFrame.new((h(47) - 0.5) * 8, 0, 4.8), h)
		end
	elseif kind == "atrium" then
		if h(48) < 0.45 then
			boiler(parent, at * CFrame.new((h(49) - 0.5) * 6, 0, (h(50) - 0.5) * 6), h, H)
		elseif h(48) < 0.7 then
			pump(parent, at * CFrame.new((h(49) - 0.5) * 6, 0, (h(50) - 0.5) * 6))
		end
		grime(parent, "oil_stain", CFrame.new(c + Vector3.new((h(51) - 0.5) * 10, 0.02, (h(55) - 0.5) * 10)) * CFrame.Angles(0, h(56) * 6, 0), Vector3.new(4 + h(57) * 4, 0.04, 3 + h(58) * 3), Enum.NormalId.Top, 0.1)
	elseif kind == "room" then
		local roll = h(52)
		local spot = at * CFrame.new((h(53) - 0.5) * 10, 0, (h(54) - 0.5) * 10)
		if roll < 0.18 then
			drum(parent, spot, h)
			if h(55) < 0.6 then
				drum(parent, spot * CFrame.new(2.4, 0, 0.3), function(n)
					return h(n + 7)
				end)
			end
			grime(parent, "oil_stain", spot * CFrame.new(1, 0.02, -2), Vector3.new(4, 0.04, 3), Enum.NormalId.Top, 0.15)
		elseif roll < 0.3 then
			pump(parent, spot)
		end
	elseif kind == "hall" then
		if h(62) < 0.06 then
			drum(parent, at * CFrame.new(6.5, 0, (h(63) - 0.5) * 10), h)
		end
	else
		if h(65) < 0.03 then
			drum(parent, at * CFrame.new(6.5, 0, (h(66) - 0.5) * 10), h)
		end
	end
end

-- Dresses one cell of a set piece.
local function dressCell(parent: Instance, kind: string, room: LevelGen.Room, x: number, z: number, seed: number)
	local function h(n: number): number
		return hash(x * 7 + n, z * 13 - n, n * 3.1, seed)
	end
	local c = LevelBuilder.cellCenter(x, z)
	local yaw = math.floor(h(0) * 4) * math.rad(90) + (h(99) - 0.5) * 0.12
	local at = CFrame.new(c) * CFrame.Angles(0, yaw, 0)
	if KIND == "ward" then
		dressWard(parent, kind, room, c, at, h)
		return
	elseif KIND == "plant" then
		dressPlant(parent, kind, room, c, at, h)
		return
	end
	-- The Carpet: an abandoned office floor.
	if kind == "office" then
		desk(parent, at * CFrame.new((h(41) - 0.5) * 4, 0, (h(42) - 0.5) * 4), h)
		if h(43) < 0.35 then
			filingCabinet(parent, at * CFrame.new(7, 0, (h(44) - 0.5) * 10) * CFrame.Angles(0, math.rad(90), 0))
		end
		if h(68) < 0.45 then
			wastebin(parent, at * CFrame.new((h(69) - 0.5) * 4 + 3.2, 0, -1.6), h)
		end
		if h(82) < 0.35 then
			binders(parent, at * CFrame.new((h(41) - 0.5) * 4 - 2.2, 2.73, (h(42) - 0.5) * 4 - 0.6), h)
		end
		if h(83) < 0.08 then
			waterCooler(parent, at * CFrame.new(-7.5, 0, (h(84) - 0.5) * 10))
		end
	elseif kind == "storage" then
		-- Racks in rows along the room's long side.
		local alongX = room.w >= room.d
		local rackYaw = if alongX then 0 else math.rad(90)
		shelving(parent, CFrame.new(c) * CFrame.Angles(0, rackYaw, 0) * CFrame.new(0, 0, -4), h)
		-- No loose boxes on the floor: anything box-sized down there reads
		-- as loot (Jason). A cabinet at the end of the aisle instead.
		if h(45) < 0.35 then
			filingCabinet(parent, CFrame.new(c) * CFrame.Angles(0, rackYaw, 0) * CFrame.new((h(47) - 0.5) * 6, 0, 4.6) * CFrame.Angles(0, math.rad(180), 0))
		end
	elseif kind == "atrium" then
		if h(48) < 0.3 then
			puddle(parent, CFrame.new(c + Vector3.new((h(49) - 0.5) * 12, 0, (h(50) - 0.5) * 12)), 4 + h(51) * 6)
		end
	elseif kind == "room" then
		local roll = h(52)
		if roll < 0.18 then
			-- A cabinet pushed against the side of the room (was a stack of
			-- boxes, which looked like loot).
			filingCabinet(parent, at * CFrame.new(7.5, 0, (h(54) - 0.5) * 10) * CFrame.Angles(0, math.rad(90), 0))
		elseif roll < 0.3 then
			chair(parent, at * CFrame.new((h(56) - 0.5) * 10, 0, (h(57) - 0.5) * 10), h(58) < 0.3)
		elseif roll < 0.38 then
			puddle(parent, CFrame.new(c + Vector3.new((h(59) - 0.5) * 10, 0, (h(60) - 0.5) * 10)), 3 + h(61) * 4)
		elseif roll < 0.44 then
			waterCooler(parent, at * CFrame.new(7.5, 0, (h(84) - 0.5) * 10))
		elseif roll < 0.48 then
			fallenTile(parent, at * CFrame.new((h(87) - 0.5) * 8, 0, (h(88) - 0.5) * 8), h)
		end
	elseif kind == "hall" then
		if h(62) < 0.07 then
			chair(parent, at * CFrame.new(0, 0, (h(63) - 0.5) * 12), h(64) < 0.5)
		end
	else -- plain corridor
		local roll = h(65)
		if roll < 0.03 then
			chair(parent, at * CFrame.new(6, 0, (h(66) - 0.5) * 10) * CFrame.Angles(0, h(64) * 6, 0), false)
		elseif roll < 0.045 then
			chair(parent, at * CFrame.new(5, 0, (h(67) - 0.5) * 10), true)
		elseif roll < 0.06 then
			fallenTile(parent, at * CFrame.new(0, 0, (h(67) - 0.5) * 8), h)
		end
	end
end

-- STRUCTURE (rebuilt by the Shift) --------------------------------------------

local panelsByModel: { [Instance]: { [number]: BasePart } } = {}
local slotsByModel: { [Instance]: { { cf: CFrame, width: number } } } = {}

-- Shelf gaps in a level as last built (they change with every Shift).
function LevelBuilder.shelfSlots(model: Instance): { { cf: CFrame, width: number } }
	return slotsByModel[model] or {}
end

-- Switches each fitting to match its cell's light state ("on", "flicker",
-- "dead"). The server only sets the LightState attribute and the tags;
-- each device does the visuals (main.client), so a Shift can't flash
-- lights on in the middle of its blackout. Tags: LightFitting (every
-- panel), CeilingLight (working, blacked out by the Shift), FlickerLight
-- (stutters, and where Lampjaw hides).
-- The light fitting over a cell (key = x * 1000 + z), if it has one.
function LevelBuilder.lightPanel(model: Instance, key: number): BasePart?
	local panels = panelsByModel[model]
	return panels and panels[key]
end

function LevelBuilder.applyLights(layout: LevelGen.Layout, model: Instance)
	local panels = panelsByModel[model]
	if not panels then
		return
	end
	for x = 1, layout.width do
		for z = 1, layout.depth do
			local panel = panels[x * 1000 + z]
			if panel then
				local st = layout.cells[x][z].light
				local dead = st == "dead"
				if panel:GetAttribute("LightState") == nil then
					-- First build: set the look on the server too, for anyone
					-- whose device hasn't run its light script yet.
					panel.Color = if dead then COLORS.lightDead else COLORS.lightOn
					panel.Material = if dead then Enum.Material.Glass else Enum.Material.Neon
					local tubes = panel:FindFirstChild("Tubes")
					if tubes and tubes:IsA("BasePart") then
						tubes.Color = panel.Color
						tubes.Material = panel.Material
					end
					local light = panel:FindFirstChildOfClass("SurfaceLight")
					if light then
						light.Enabled = not dead
					end
					CollectionService:AddTag(panel, "LightFitting")
				end
				panel:SetAttribute("LightState", st)
				if dead then
					CollectionService:RemoveTag(panel, "CeilingLight")
				else
					CollectionService:AddTag(panel, "CeilingLight")
				end
				if st == "flicker" then
					CollectionService:AddTag(panel, "FlickerLight")
				else
					CollectionService:RemoveTag(panel, "FlickerLight")
				end
			end
		end
	end
end

function LevelBuilder.buildStructure(layout: LevelGen.Layout, model: Instance)
	local S, H, T = LevelBuilder.CELL, LevelBuilder.HEIGHT, LevelBuilder.THICK
	local W, D = layout.width, layout.depth
	local seed = layout.seed
	local cells = layout.cells

	local old = model:FindFirstChild("Structure")
	if old then
		old:Destroy()
	end
	ORIGIN = (model:GetAttribute("Origin") or Vector3.zero) :: Vector3
	SLOTS = {}
	local theme = themes[model]
	if theme then
		for k, v in theme.colors do
			COLORS[k] = v
		end
		for k, v in theme.materials do
			MATERIALS[k] = v
		end
		for k, v in theme.variants do
			VARIANTS[k] = v
		end
		KIND = theme.kind
	end
	local structure = Instance.new("Folder")
	structure.Name = "Structure"
	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	walls.Parent = structure
	local details = Instance.new("Folder")
	details.Name = "Details"
	details.Parent = structure
	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = structure

	-- Slightly different shade per wall run, so walls look patchy and aged.
	local function agedWallColor(a: number, b: number): Color3
		local shade = 0.86 + hash(a, b, 1, seed) * 0.16
		local c = COLORS.wall
		return Color3.new(c.R * shade, c.G * shade, c.B * (shade - 0.04))
	end

	-- The Blender wall: a panel per cell along each run (the run's part stays
	-- as the collider), wallpaper peeling off here and there on The Carpet,
	-- and a post wherever walls turn, meet or end. Each segment remembers
	-- its run's parts so the posts can take their colour.
	local segs: { [number]: { wall: BasePart, skirt: BasePart } } = {}
	local function segKey(alongX: boolean, line: number, cell: number): number
		return (if alongX then 1 else 2) * 1000000 + line * 1000 + cell
	end
	local modular = S == 20 and H == 11
	local function panels(wall: BasePart, skirt: BasePart, alongX: boolean, line: number, c0: number, c1: number)
		local list = {}
		for c = c0, c1 do
			segs[segKey(alongX, line, c)] = { wall = wall, skirt = skirt }
			local centre = if alongX then Vector3.new((c - 0.5) * S, 0, line * S) else Vector3.new(line * S, 0, (c - 0.5) * S)
			local peel = KIND == "carpet" and hash(centre.X + 3, centre.Z - 7, 5.5, seed) < 0.12 and Meshes.ready("wall_panel_peeling")
			local flip = hash(centre.Z + 11, centre.X - 2, 9.1, seed) < 0.5 -- which face peels
			local yaw = (if alongX then 0 else math.pi / 2) + (if flip then math.pi else 0)
			table.insert(list, { name = if peel then "wall_panel_peeling" else "wall_panel_skirting", cf = CFrame.new(centre + ORIGIN) * CFrame.Angles(0, yaw, 0) })
		end
		if not modular then
			return
		end
		-- The run's own parts go when the plain panel arrives (or the only one).
		local holder = list[1]
		for _, seg in list do
			if seg.name == "wall_panel_skirting" then
				holder = seg
				break
			end
		end
		for _, seg in list do
			Meshes.dress(seg.name, seg.cf, walls, if seg == holder then { wall, skirt } else {}, { copy = { Wall = wall, Skirting = skirt } })
		end
	end

	local function wallX(xLine: number, z0: number, z1: number)
		-- Wall running north-south along X = xLine * S, covering cells z0..z1.
		local w = makePart({
			Name = "Wall",
			Size = Vector3.new(T, H, (z1 - z0 + 1) * S + T),
			Position = Vector3.new(xLine * S, H / 2, ((z0 - 1) * S + z1 * S) / 2),
			Color = agedWallColor(xLine, z0),
			Material = MATERIALS.wall,
		}, walls)
		surface(w, "wall")
		local skirt = detail({
			Name = "Skirting",
			Size = Vector3.new(T + 0.3, 0.7, (z1 - z0 + 1) * S + T + 0.3),
			Position = Vector3.new(xLine * S, 0.35, ((z0 - 1) * S + z1 * S) / 2),
			Color = COLORS.skirting,
			Material = MATERIALS.trim,
		}, walls)
		panels(w, skirt, false, xLine, z0, z1)
	end
	local function wallZ(zLine: number, x0: number, x1: number)
		-- Wall running east-west along Z = zLine * S, covering cells x0..x1.
		local w = makePart({
			Name = "Wall",
			Size = Vector3.new((x1 - x0 + 1) * S + T, H, T),
			Position = Vector3.new(((x0 - 1) * S + x1 * S) / 2, H / 2, zLine * S),
			Color = agedWallColor(x0 + 500, zLine),
			Material = MATERIALS.wall,
		}, walls)
		surface(w, "wall")
		local skirt = detail({
			Name = "Skirting",
			Size = Vector3.new((x1 - x0 + 1) * S + T + 0.3, 0.7, T + 0.3),
			Position = Vector3.new(((x0 - 1) * S + x1 * S) / 2, 0.35, zLine * S),
			Color = COLORS.skirting,
			Material = MATERIALS.trim,
		}, walls)
		panels(w, skirt, true, zLine, x0, x1)
	end

	-- Outer west and north border (east/south borders come from the cells).
	wallX(0, 1, D)
	wallZ(0, 1, W)
	-- East walls, merged into runs per column line.
	for x = 1, W do
		local runStart: number? = nil
		for z = 1, D + 1 do
			local present = z <= D and cells[x][z].wallEast
			if present and not runStart then
				runStart = z
			elseif not present and runStart then
				wallX(x, runStart, z - 1)
				runStart = nil
			end
		end
	end
	-- South walls, merged into runs per row line.
	for z = 1, D do
		local runStart: number? = nil
		for x = 1, W + 1 do
			local present = x <= W and cells[x][z].wallSouth
			if present and not runStart then
				runStart = x
			elseif not present and runStart then
				wallZ(z, runStart, x - 1)
				runStart = nil
			end
		end
	end

	-- Wall details, per wall segment and per face, so they're stable
	-- through a Shift: outlets, vents, and water stains running down from
	-- the ceiling. `frame` faces the room: origin on the wall face at
	-- floor height, X along the wall, -Z out of the wall.
	local function dressWall(frame: CFrame, a: number, b: number)
		local function h(n: number): number
			return hash(a * 3 + n, b * 5 - n, n, seed)
		end
		local along = (h(1) - 0.5) * (S - 4)
		if h(2) < 0.07 then
			local outlet = { detail({ Name = "Outlet", Size = Vector3.new(0.55, 0.85, 0.08), CFrame = frame * CFrame.new(along, 1.4, -0.04), Color = Color3.fromRGB(226, 220, 200), Material = Enum.Material.Plastic }, details) }
			for _, dy in { 0.18, -0.18 } do
				table.insert(outlet, detail({ Name = "Socket", Size = Vector3.new(0.22, 0.14, 0.04), CFrame = frame * CFrame.new(along, 1.4 + dy, -0.09), Color = DARK, Material = Enum.Material.Plastic }, details))
			end
			Meshes.dress("wall_outlet", frame * CFrame.new(along, 0, 0) + ORIGIN, details, outlet)
		end
		if h(3) < 0.035 then
			local vy = H - 1.3
			Meshes.dress("vent_grate", frame * CFrame.new(-along * 0.5, vy, 0) + ORIGIN, details, {
				detail({ Name = "VentFrame", Size = Vector3.new(2.6, 1.3, 0.1), CFrame = frame * CFrame.new(-along * 0.5, vy, -0.05), Color = Color3.fromRGB(176, 172, 160), Material = Enum.Material.Metal }, details),
				detail({ Name = "VentGrille", Size = Vector3.new(2.2, 0.95, 0.06), CFrame = frame * CFrame.new(-along * 0.5, vy, -0.1), Color = Color3.fromRGB(40, 38, 34), Material = Enum.Material.DiamondPlate }, details),
			})
		end
		local FRONT = Enum.NormalId.Front
		if h(4) < 0.09 then
			local sw, sh = 1.5 + h(5) * 4, 2 + h(6) * 5
			local sx = (h(7) - 0.5) * (S - sw - 2)
			local key = if KIND == "plant" then "rust_streak" else "drip_stain"
			if not grime(details, key, frame * CFrame.new(sx, H - sh / 2, -0.05), Vector3.new(sw, sh, 0.05), FRONT, 0) then
				detail({
					Name = "WaterStain",
					Size = Vector3.new(sw, sh, 0.04),
					CFrame = frame * CFrame.new(sx, H - sh / 2, -0.03),
					Color = COLORS.stain,
					Material = Enum.Material.Plastic,
					Transparency = 0.55 + h(8) * 0.25,
				}, details)
				-- A darker tide line where the water stopped.
				detail({
					Name = "StainEdge",
					Size = Vector3.new(sw * 0.8, 0.25, 0.04),
					CFrame = frame * CFrame.new(sx, H - sh + 0.15, -0.035),
					Color = COLORS.stain:Lerp(Color3.new(0, 0, 0), 0.3),
					Material = Enum.Material.Plastic,
					Transparency = 0.5,
				}, details)
			end
		end
		-- Lived-in grime (decals, once uploaded): dirt banked along the
		-- skirting, scuffs, smudges at hand height, paper peeling at the top.
		if h(9) < 0.14 then
			grime(details, "corner_grime", frame * CFrame.new((h(10) - 0.5) * (S - 8), 1.9, -0.05), Vector3.new(6 + h(11) * 6, 2.4, 0.05), FRONT, 0.1)
		end
		if KIND ~= "plant" and h(12) < 0.09 then
			grime(details, "scuff", frame * CFrame.new((h(13) - 0.5) * (S - 9), 1.45, -0.06), Vector3.new(8, 1.4, 0.05), FRONT, 0.05)
		end
		if h(14) < 0.05 then
			grime(details, "wall_grime", frame * CFrame.new((h(15) - 0.5) * (S - 6), 4, -0.07), Vector3.new(5, 4, 0.05), FRONT, 0.15)
		end
		if KIND == "carpet" and h(16) < 0.07 then
			grime(details, "peel", frame * CFrame.new((h(17) - 0.5) * (S - 7), H - 1.1, -0.08), Vector3.new(6, 2.2, 0.05), FRONT, 0)
		end
		if KIND == "ward" and h(18) < 0.16 then
			-- A hospital handrail along the corridor wall.
			local rail = { detail({ Name = "Handrail", Size = Vector3.new(S - 3, 0.25, 0.25), CFrame = frame * CFrame.new(0, 3.1, -0.45), Color = Color3.fromRGB(150, 128, 96), Material = Enum.Material.Wood }, details) }
			for _, bx in { -(S - 5) / 2, 0, (S - 5) / 2 } do
				table.insert(rail, detail({ Name = "RailBracket", Size = Vector3.new(0.15, 0.15, 0.45), CFrame = frame * CFrame.new(bx, 3.0, -0.22), Color = Color3.fromRGB(170, 172, 170), Material = Enum.Material.Metal }, details))
			end
			if S == 20 then
				Meshes.dress("handrail", frame + ORIGIN, details, rail)
			end
		end
		if KIND == "plant" and h(19) < 0.18 then
			-- A pipe run along the top of the wall, on brackets; sometimes a
			-- drop to a valve and a gauge. Rust runs down from the joints.
			local drops = h(22) < 0.5
			local py = H - 1.6 - h(20) * 1.4
			if drops and Meshes.has("pipe_drop") and H == 11 then
				py = H - 2.3 -- where the Blender drop's tee is
			end
			-- The Blender pipe run has its middle flange at x = 1.5; the rust runs from there.
			local fx = if Meshes.has("pipe_run") and S == 20 then 1.5 else (h(21) - 0.5) * (S - 6)
			local run = { detail({ Name = "Pipe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(S, 0.7, 0.7), CFrame = frame * CFrame.new(0, py, -0.6), Color = PIPE, Material = Enum.Material.Metal }, details) }
			for _, bx in { -S / 2 + 2, 0, S / 2 - 2 } do
				table.insert(run, detail({ Name = "PipeBracket", Size = Vector3.new(0.25, 1.0, 0.75), CFrame = frame * CFrame.new(bx, py, -0.38), Color = Color3.fromRGB(50, 48, 44), Material = Enum.Material.Metal }, details))
			end
			table.insert(run, detail({ Name = "PipeFlange", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 0.95, 0.95), CFrame = frame * CFrame.new(fx, py, -0.6), Color = Color3.fromRGB(80, 74, 66), Material = Enum.Material.CorrodedMetal }, details))
			if S == 20 then
				Meshes.dress("pipe_run", frame * CFrame.new(0, py, 0) + ORIGIN, details, run)
			end
			grime(details, "rust_streak", frame * CFrame.new(fx, py - 2.6, -0.05), Vector3.new(2.2, 4.4, 0.05), FRONT, 0)
			if drops then
				local vx = (h(23) - 0.5) * (S - 6)
				local drop = py - 3.2
				local parts = valve(details, frame * CFrame.new(vx, 3.6, -1.05))
				table.insert(parts, detail({ Name = "Pipe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(drop, 0.45, 0.45), CFrame = frame * CFrame.new(vx, 3.2 + drop / 2, -0.6) * CFrame.Angles(0, 0, math.rad(90)), Color = PIPE, Material = Enum.Material.Metal }, details))
				table.insert(parts, detail({ Name = "Gauge", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 0.75, 0.75), CFrame = frame * CFrame.new(vx + 0.75, 4.8, -0.75) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(214, 208, 190), Material = Enum.Material.Plastic }, details))
				if H == 11 then
					Meshes.dress("pipe_drop", frame * CFrame.new(vx, 0, 0) + ORIGIN, details, parts)
				end
			end
		end
		-- Blender-only dressing (nothing stands in for these until they're
		-- uploaded): a cork notice board on office-y walls, a cable tray
		-- along the top of Plant walls that have no pipe run.
		if modular and KIND ~= "plant" and h(26) < 0.025 then
			Meshes.dress("notice_board", frame * CFrame.new((h(27) - 0.5) * (S - 8), 3.6, 0) + ORIGIN, details, {})
		end
		if modular and KIND == "plant" and h(19) >= 0.18 and h(28) < 0.05 then
			Meshes.dress("cable_tray", frame * CFrame.new(0, H - 1.4, 0) + ORIGIN, details, {})
		end
		if KIND == "plant" and h(24) < 0.05 then
			local jx = (h(25) - 0.5) * (S - 4)
			local parts = {
				detail({ Name = "JunctionBox", Size = Vector3.new(1.6, 2.0, 0.5), CFrame = frame * CFrame.new(jx, 5, -0.25), Color = Color3.fromRGB(90, 96, 90), Material = Enum.Material.Metal }, details),
				detail({ Name = "Conduit", Size = Vector3.new(0.2, H - 6, 0.2), CFrame = frame * CFrame.new(jx, 6 + (H - 6) / 2, -0.2), Color = Color3.fromRGB(110, 110, 104), Material = Enum.Material.Metal }, details),
			}
			if H == 11 then
				Meshes.dress("junction_box", frame * CFrame.new(jx, 0, 0) + ORIGIN, details, parts)
			end
		end
	end
	local half = T / 2
	for x = 0, W do
		for z = 1, D do
			-- Wall on X line x between cells (x, z) and (x+1, z).
			local present = x == 0 or x == W or cells[x][z].wallEast
			if present then
				local mid = Vector3.new(x * S, 0, (z - 0.5) * S)
				if x < W then -- face looking east into cell x+1
					dressWall(CFrame.lookAt(mid + Vector3.new(half, 0, 0), mid + Vector3.new(half + 1, 0, 0) ), x * 2 + 1, z)
				end
				if x > 0 then -- face looking west into cell x
					dressWall(CFrame.lookAt(mid - Vector3.new(half, 0, 0), mid - Vector3.new(half + 1, 0, 0) ), x * 2, z + 400)
				end
			end
		end
	end
	for z = 0, D do
		for x = 1, W do
			local present = z == 0 or z == D or cells[x][z].wallSouth
			if present then
				local mid = Vector3.new((x - 0.5) * S, 0, z * S)
				if z < D then
					dressWall(CFrame.lookAt(mid + Vector3.new(0, 0, half), mid + Vector3.new(0, 0, half + 1) ), x + 800, z * 2 + 1)
				end
				if z > 0 then
					dressWall(CFrame.lookAt(mid - Vector3.new(0, 0, half), mid - Vector3.new(0, 0, half + 1) ), x + 1200, z * 2)
				end
			end
		end
	end

	-- Rooms by cell, for set-piece dressing and doorways.
	local roomAt: { [number]: LevelGen.Room } = {}
	for _, room in layout.rooms do
		for x = room.x, room.x + room.w - 1 do
			for z = room.z, room.z + room.d - 1 do
				if cells[x][z].room then
					roomAt[x * 1000 + z] = room
				end
			end
		end
	end

	-- Doorways: offices and storage rooms get a proper door-sized opening
	-- (wall stubs and a header) where they meet a corridor, so they read as
	-- rooms rather than gaps. Size in Config (wide enough to haul loot through).
	local DOOR_W, DOOR_H = Config.DOOR_WIDTH, Config.DOOR_HEIGHT
	local function doorway(mid: Vector3, alongX: boolean, key: number)
		local stub = (S - DOOR_W) / 2
		local trim = {}
		local shell: { BasePart } = {}
		local skirts: { BasePart } = {}
		for _, side in { -1, 1 } do
			local offset = side * (DOOR_W / 2 + stub / 2)
			local w = makePart({
				Name = "DoorStub",
				Size = if alongX then Vector3.new(stub, H, T) else Vector3.new(T, H, stub),
				Position = mid + (if alongX then Vector3.new(offset, H / 2, 0) else Vector3.new(0, H / 2, offset)),
				Color = agedWallColor(mid.X, mid.Z),
				Material = MATERIALS.wall,
			}, walls)
			surface(w, "wall")
			table.insert(shell, w)
			table.insert(skirts, detail({
				Name = "Skirting",
				Size = if alongX then Vector3.new(stub, 0.7, T + 0.3) else Vector3.new(T + 0.3, 0.7, stub),
				Position = mid + (if alongX then Vector3.new(offset, 0.35, 0) else Vector3.new(0, 0.35, offset)),
				Color = COLORS.skirting,
				Material = MATERIALS.trim,
			}, walls))
			trim[#trim + 1] = detail({
				Name = "DoorJamb",
				Size = if alongX then Vector3.new(0.35, DOOR_H, T + 0.4) else Vector3.new(T + 0.4, DOOR_H, 0.35),
				Position = mid + (if alongX then Vector3.new(side * DOOR_W / 2, DOOR_H / 2, 0) else Vector3.new(0, DOOR_H / 2, side * DOOR_W / 2)),
				Color = COLORS.skirting,
				Material = Enum.Material.Wood,
			}, details)
		end
		local header = makePart({
			Name = "DoorHeader",
			Size = if alongX then Vector3.new(DOOR_W, H - DOOR_H, T) else Vector3.new(T, H - DOOR_H, DOOR_W),
			Position = mid + Vector3.new(0, (H + DOOR_H) / 2, 0),
			Color = agedWallColor(mid.Z, mid.X),
			Material = MATERIALS.wall,
		}, walls)
		surface(header, "wall")
		segs[key] = { wall = shell[1], skirt = skirts[1] }
		if modular and DOOR_W == 9 and DOOR_H == 8.5 then
			-- The Blender wall panel with the doorway cut through it.
			local at = CFrame.new(mid + ORIGIN) * (if alongX then CFrame.identity else CFrame.Angles(0, math.rad(90), 0))
			Meshes.dress("wall_doorway", at, walls, { shell[1], shell[2], header, skirts[1], skirts[2] }, { copy = { Wall = shell[1], Skirting = skirts[1] } })
		end
		table.insert(trim, detail({
			Name = "DoorLintel",
			Size = if alongX then Vector3.new(DOOR_W + 0.7, 0.35, T + 0.4) else Vector3.new(T + 0.4, 0.35, DOOR_W + 0.7),
			Position = mid + Vector3.new(0, DOOR_H + 0.17, 0),
			Color = COLORS.skirting,
			Material = Enum.Material.Wood,
		}, details))
		-- The Blender door frame (modelled for a 9 x 8.5 opening, X across
		-- it). Frame only: the leaves would stand in the way of hauling loot.
		if DOOR_W == 9 and DOOR_H == 8.5 then
			local at = CFrame.new(mid + ORIGIN) * (if alongX then CFrame.identity else CFrame.Angles(0, math.rad(90), 0))
			Meshes.dress("door", at, details, trim, { only = { "Door_Frame" }, copy = { Door_Frame = trim[1] } })
		end
	end
	local function needsDoor(a: LevelGen.Room?, b: LevelGen.Room?): boolean
		if a == b then
			return false
		end
		local function enclosed(r: LevelGen.Room?): boolean
			return r ~= nil and (r.kind == "office" or r.kind == "storage")
		end
		return enclosed(a) or enclosed(b)
	end
	for x = 1, W do
		for z = 1, D do
			local here = roomAt[x * 1000 + z]
			if x < W and not cells[x][z].wallEast and needsDoor(here, roomAt[(x + 1) * 1000 + z]) then
				doorway(Vector3.new(x * S, 0, (z - 0.5) * S), false, segKey(false, x, z))
			end
			if z < D and not cells[x][z].wallSouth and needsDoor(here, roomAt[x * 1000 + z + 1]) then
				doorway(Vector3.new((x - 0.5) * S, 0, z * S), true, segKey(true, z, x))
			end
		end
	end

	-- Wall posts where walls turn, meet or end (a straight run just shows
	-- the seam between two panels). They cover the panels' cut ends.
	if modular and Meshes.has("wall_post") then
		for gx = 0, W do
			for gz = 0, D do
				local e, w = segs[segKey(true, gz, gx + 1)], segs[segKey(true, gz, gx)]
				local s, n = segs[segKey(false, gx, gz + 1)], segs[segKey(false, gx, gz)]
				local any = e or w or s or n
				if any and not ((e and w and not n and not s) or (n and s and not e and not w)) then
					Meshes.dress("wall_post", CFrame.new(Vector3.new(gx * S, 0, gz * S) + ORIGIN), walls, {}, { copy = { Post = any.wall, Skirting = any.skirt } })
				end
			end
		end
	end

	-- Pillars in open rooms and atriums, at the inner grid corners. Only
	-- where all four cells meeting there are still room cells (a Shift can
	-- rewire half a room).
	local pillarAt: { [number]: boolean } = {}
	for _, room in layout.rooms do
		if room.kind ~= "room" and room.kind ~= "atrium" then
			continue
		end
		for x = room.x, room.x + room.w - 2 do
			for z = room.z, room.z + room.d - 2 do
				if pillarAt[x * 1000 + z] then
					continue
				end
				if not (cells[x][z].room and cells[x + 1][z].room and cells[x][z + 1].room and cells[x + 1][z + 1].room) then
					continue
				end
				pillarAt[x * 1000 + z] = true
				local pillar = makePart({
					Name = "Pillar",
					Size = Vector3.new(2.4, H, 2.4),
					Position = Vector3.new(x * S, H / 2, z * S),
					Color = COLORS.pillar,
					Material = MATERIALS.wall,
				}, walls)
				surface(pillar, "wall")
				local base = detail({ Name = "PillarBase", Size = Vector3.new(2.8, 0.7, 2.8), Position = Vector3.new(x * S, 0.35, z * S), Color = COLORS.skirting, Material = MATERIALS.trim }, walls)
				if H == 11 then
					Meshes.dress("pillar", CFrame.new(Vector3.new(x * S, 0, z * S) + ORIGIN), walls, { pillar, base }, { copy = { Pillar = pillar, Trim = base } })
				end
			end
		end
	end

	-- Props: dress every cell by what it belongs to.
	for x = 1, W do
		for z = 1, D do
			local room = roomAt[x * 1000 + z]
			if not (x == layout.spawn.x and z == layout.spawn.z) and not (x == layout.exit.x and z == layout.exit.z) then
				dressCell(props, if room then room.kind else "corridor", room or ({ x = x, z = z, w = 1, d = 1, kind = "corridor" } :: any), x, z, seed)
			end
		end
	end

	slotsByModel[model] = SLOTS
	structure.Parent = model
	LevelBuilder.applyLights(layout, model)
end

-- STATIC LAYER -----------------------------------------------------------------

function LevelBuilder.build(layout: LevelGen.Layout, parent: Instance, origin: Vector3?, crew: number?): Model
	local S, H, T = LevelBuilder.CELL, LevelBuilder.HEIGHT, LevelBuilder.THICK
	local W, D = layout.width, layout.depth
	local seed = layout.seed
	ORIGIN = origin or Vector3.zero

	local model = Instance.new("Model")
	model.Name = if crew then `Level{crew}` else "Level"
	model:SetAttribute("Seed", layout.seed)
	model:SetAttribute("Origin", ORIGIN)
	model:SetAttribute("Crew", crew or 0)
	themes[model] = { colors = table.clone(COLORS), materials = table.clone(MATERIALS), variants = table.clone(VARIANTS), kind = KIND }
	model.Destroying:Connect(function()
		themes[model] = nil
		panelsByModel[model] = nil
		slotsByModel[model] = nil
	end)

	-- Floor and ceiling: one big slab each.
	local floor = makePart({
		Name = "Floor",
		Size = Vector3.new(W * S + T, 1, D * S + T),
		Position = Vector3.new(W * S / 2, -0.5, D * S / 2),
		Color = COLORS.carpet,
		Material = MATERIALS.carpet,
	}, model)
	surface(floor, "carpet")
	local ceiling = makePart({
		Name = "Ceiling",
		Size = Vector3.new(W * S + T, 1, D * S + T),
		Position = Vector3.new(W * S / 2, H + 0.5, D * S / 2),
		Color = COLORS.ceiling,
		Material = MATERIALS.ceiling,
	}, model)
	surface(ceiling, "ceiling")

	-- Suspended-ceiling grid: thin strips every quarter cell, both ways.
	local ceilingFolder = Instance.new("Folder")
	ceilingFolder.Name = "CeilingGrid"
	ceilingFolder.Parent = model
	local step = S / 4
	local strips: { BasePart } = {}
	for i = 0, math.floor(W * S / step) do
		table.insert(strips, detail({ Name = "GridX", Size = Vector3.new(0.25, 0.1, D * S), Position = Vector3.new(i * step, H - 0.05, D * S / 2), Color = COLORS.grid, Material = MATERIALS.trim }, ceilingFolder))
	end
	for i = 0, math.floor(D * S / step) do
		table.insert(strips, detail({ Name = "GridZ", Size = Vector3.new(W * S, 0.1, 0.25), Position = Vector3.new(W * S / 2, H - 0.05, i * step), Color = COLORS.grid, Material = MATERIALS.trim }, ceilingFolder))
	end

	-- The Blender floor tiles and ceiling panels, a cell at a time. The
	-- slabs stay as what you walk on and the lid (invisible once the panels
	-- are in); the strips above go. A few floors have a tile gone or curling
	-- (not the Plant's steel), and a missing ceiling tile is a panel with a
	-- tile hanging out of the grid.
	local modular = S == 20 and H == 11
	local floorMesh = modular and Meshes.has("floor_panel")
	local ceilingMesh = modular and Meshes.has("ceiling_tile")
	local tilesFolder = Instance.new("Folder")
	tilesFolder.Name = "Tiles"
	tilesFolder.Parent = model
	local floorHeld, ceilingHeld = false, false
	local function floorPanel(x: number, z: number, h: (number) -> number)
		local c = LevelBuilder.cellCenter(x, z)
		local damaged = KIND ~= "plant" and h(21) < 0.04 and Meshes.ready("floor_panel_damaged")
		local yaw = math.floor(h(22) * 4) * math.rad(90)
		local prims = if not damaged and not floorHeld then { floor } else {}
		floorHeld = floorHeld or #prims > 0
		Meshes.dress(if damaged then "floor_panel_damaged" else "floor_panel", CFrame.new(Vector3.new(c.X, -0.12, c.Z) + ORIGIN) * CFrame.Angles(0, yaw, 0), tilesFolder, prims, { copy = { Carpet = floor } })
	end
	local function ceilingPanel(x: number, z: number, gap: { tx: number, tz: number, hole: BasePart }?)
		local c = LevelBuilder.cellCenter(x, z)
		local at = CFrame.new(Vector3.new(c.X, H - 0.2, c.Z) + ORIGIN)
		local copy = { copy = { Tiles = ceiling, Grid = strips[1] } }
		if gap then
			-- Modelled with the hole in the (0, 0) corner; turned to the one picked.
			local yaw = if gap.tx == 0 then (if gap.tz == 0 then 0 else 90) else (if gap.tz == 0 then -90 else 180)
			Meshes.dress("ceiling_tile_gap", at * CFrame.Angles(0, math.rad(yaw), 0), tilesFolder, { gap.hole }, copy)
		else
			local prims = if ceilingHeld then {} else { ceiling, table.unpack(strips) }
			ceilingHeld = true
			Meshes.dress("ceiling_tile", at, tilesFolder, prims, copy)
		end
	end

	-- Damage: stained or missing ceiling tiles and damp patches on the floor.
	local damage = Instance.new("Folder")
	damage.Name = "Damage"
	damage.Parent = model
	for x = 1, W do
		for z = 1, D do
			local c = LevelBuilder.cellCenter(x, z)
			local function h(n: number): number
				return hash(x * 11 + n, z * 17 + n, n * 1.7, seed)
			end
			-- Ceiling tiles are 5x5 studs; pick one of the 16 in this cell
			-- that isn't where the light fitting hangs. (Under the Blender
			-- panels, stains go just below the tiles' undersides.)
			local tx, tz = math.floor(h(1) * 4), math.floor(h(2) * 4)
			local onLight = (tx == 1 or tx == 2) and (tz == 1 or tz == 2)
			local roll = if onLight then 1 else h(3)
			local gap = ceilingMesh and roll < 0.05 and Meshes.ready("ceiling_tile_gap")
			if gap then
				-- The Blender panel with a tile down has its hole in a corner.
				tx = if tx < 2 then 0 else 3
				tz = if tz < 2 then 0 else 3
			end
			local tile = Vector3.new(c.X - S / 2 + (tx + 0.5) * step, if ceilingMesh then H - 0.17 else H - 0.03, c.Z - S / 2 + (tz + 0.5) * step)
			local hole: BasePart? = nil
			if not onLight then
				if roll < 0.05 then
					-- Missing tile: a black hole into the ceiling void.
					hole = detail({ Name = "MissingTile", Size = Vector3.new(step - 0.3, 0.04, step - 0.3), Position = tile, Color = Color3.fromRGB(8, 8, 8), Material = Enum.Material.Plastic }, damage)
				elseif roll < 0.2 then
					-- A water-stained tile: the tide-mark decal once uploaded.
					if not grime(damage, "water_stain", CFrame.new(tile - Vector3.new(0, 0.01, 0)) * CFrame.Angles(0, h(4) * 6, 0), Vector3.new(step - 0.4, 0.04, step - 0.4), Enum.NormalId.Bottom, 0) then
						detail({ Name = "StainedTile", Size = Vector3.new(step - 0.3, 0.04, step - 0.3), Position = tile, Color = COLORS.ceiling:Lerp(COLORS.stain, 0.35 + h(4) * 0.3), Material = MATERIALS.ceiling }, damage)
					elseif h(11) < 0.6 then
						-- And the mess it left on the floor below.
						grime(damage, if KIND == "plant" then "oil_stain" else "floor_stain", CFrame.new(Vector3.new(tile.X, 0.025, tile.Z)) * CFrame.Angles(0, h(12) * 6, 0), Vector3.new(3 + h(13) * 2, 0.04, 2.4 + h(14) * 2), Enum.NormalId.Top, 0.1)
					end
				end
			end
			if ceilingMesh then
				ceilingPanel(x, z, if gap and hole then { tx = tx, tz = tz, hole = hole } else nil)
			end
			if floorMesh then
				floorPanel(x, z, h)
			end
			-- Carpet worn into paths down the corridors.
			if KIND == "carpet" and not layout.cells[x][z].room and h(15) < 0.3 then
				local ns = layout.cells[x][z].wallEast and (x == 1 or layout.cells[x - 1][z].wallEast)
				grime(damage, "wear_path", CFrame.new(c + Vector3.new(0, 0.02, 0)) * CFrame.Angles(0, if ns then 0 else math.rad(90), 0), Vector3.new(6, 0.04, S + 2), Enum.NormalId.Top, 0.1 + h(16) * 0.3)
			end
			if h(5) < 0.1 and Grime.has(if KIND == "plant" then "oil_stain" else "floor_stain") then
				grime(damage, if KIND == "plant" then "oil_stain" else "floor_stain", CFrame.new(c + Vector3.new((h(8) - 0.5) * 12, 0.022, (h(9) - 0.5) * 12)) * CFrame.Angles(0, h(10) * 6.28, 0), Vector3.new(3 + h(6) * 5, 0.04, 2.5 + h(7) * 4), Enum.NormalId.Top, 0.05)
			elseif h(5) < 0.1 then
				local p = detail({
					Name = "DampPatch",
					Size = Vector3.new(0.02, 4 + h(6) * 7, 3 + h(7) * 5),
					CFrame = CFrame.new(c + Vector3.new((h(8) - 0.5) * 12, 0.012, (h(9) - 0.5) * 12)) * CFrame.Angles(0, h(10) * 6.28, math.rad(90)),
					Color = COLORS.carpet:Lerp(Color3.new(0, 0, 0), 0.35),
					Material = MATERIALS.carpet,
					Transparency = 0.35,
				}, damage)
				p.Shape = Enum.PartType.Cylinder
			end
		end
	end

	-- Light fittings, one per cell: a recessed troffer with a metal frame,
	-- a diffuser panel and a centre bar. Built once; the Shift only
	-- switches them (applyLights).
	local lights = Instance.new("Folder")
	lights.Name = "Lights"
	lights.Parent = model
	local panels: { [number]: BasePart } = {}
	for x = 1, W do
		for z = 1, D do
			local c = LevelBuilder.cellCenter(x, z)
			local housing = detail({ Name = "LightHousing", Size = Vector3.new(5, 0.3, 2.8), Position = Vector3.new(c.X, H - 0.15, c.Z), Color = COLORS.housing, Material = Enum.Material.Metal }, lights)
			local panel = detail({ Name = "LightPanel", Size = Vector3.new(4.4, 0.1, 2.2), Position = Vector3.new(c.X, H - 0.33, c.Z), Color = COLORS.lightOn, Material = Enum.Material.Neon }, lights)
			local bar = detail({ Name = "LightBar", Size = Vector3.new(4.4, 0.08, 0.18), Position = Vector3.new(c.X, H - 0.4, c.Z), Color = COLORS.housing, Material = Enum.Material.Metal }, lights)
			local light = Instance.new("SurfaceLight")
			light.Face = Enum.NormalId.Bottom
			light.Angle = 120
			light.Range = 20
			light.Brightness = 2
			light.Color = COLORS.lightOn
			light.Shadows = false -- shadows on ~900 lights would kill phones
			light.Parent = panel
			panel:SetAttribute("Cell", x * 1000 + z) -- lets entities find "the light over this cell"
			panel:SetAttribute("Crew", crew or 0) -- whose level this light is in
			panels[x * 1000 + z] = panel
			-- The Blender fitting with two visible tubes. The panel stays (it
			-- carries the light, tags and state) but goes invisible, and the
			-- tubes go under it, so everything that switches the panel
			-- (Shift blackouts, flicker, Lampjaw's strobe) switches the tubes.
			Meshes.dress("fixture", CFrame.new(Vector3.new(c.X, H, c.Z) + ORIGIN), lights, { housing, bar, panel }, {
				copy = { Housing = housing },
				onBuilt = function(m)
					local tubes = m:FindFirstChild("Tubes") :: BasePart?
					if tubes then
						tubes.Color = panel.Color
						tubes.Material = panel.Material
						tubes.Parent = panel
					else
						panel.Transparency = 0 -- no separate tubes in this upload: keep the panel lit
					end
				end,
			})
		end
	end
	panelsByModel[model] = panels

	LevelBuilder.buildStructure(layout, model)
	ORIGIN = origin or Vector3.zero

	-- With StreamingEnabled (new places have it on), Atomic sends the whole
	-- level at once when you get near it, so walls and lights never pop in,
	-- and other crews' levels (LEVEL_SPACING away) never reach you at all.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	model.Parent = parent
	return model
end

return LevelBuilder
