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
-- Surfaces use MaterialVariants when they exist (see Materials.luau and
-- TODO.md), otherwise Roblox's built-in materials.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelGen = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LevelGen"))
local Materials = require(script.Parent:WaitForChild("Materials"))

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
	lightOn = Color3.fromRGB(246, 242, 212), -- cold-warm fluorescent
	lightDead = Color3.fromRGB(64, 62, 56),
	pillar = Color3.fromRGB(190, 170, 96),
	stain = Color3.fromRGB(92, 70, 30), -- water damage
}

-- Built-in Roblox materials (no uploads needed).
local MATERIALS = {
	wall = Enum.Material.Plaster,
	carpet = Enum.Material.Carpet,
	ceiling = Enum.Material.Plaster,
	trim = Enum.Material.SmoothPlastic,
}

-- MaterialVariant names per surface for the current level type ("" = none).
local VARIANTS = { wall = "", carpet = "", ceiling = "" }

local DEFAULT_COLORS = table.clone(COLORS)
local DEFAULT_MATERIALS = table.clone(MATERIALS)

-- Level types (LevelTypes.luau) swap colours, materials and texture
-- variants before a build.
function LevelBuilder.setTheme(colours: { [string]: Color3 }, materials: { [string]: string }, variants: { [string]: string }?)
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
	if name and name ~= "" and Materials.has(name) then
		p.Material = Materials.base(name)
		p.MaterialVariant = name
		p.Color = Color3.new(1, 1, 1) -- the texture brings its own colour
	end
end

local function makePart(props: { [string]: any }, parent: Instance): Part
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

-- Deterministic 0..1 from a position and the seed.
local function hash(a: number, b: number, c: number, seed: number): number
	local h = math.sin(a * 12.9898 + b * 78.233 + c * 37.719 + seed * 0.0137) * 43758.5453
	return h - math.floor(h)
end

-- Is this position inside the level (not the safehouse)?
function LevelBuilder.inLevel(layout: LevelGen.Layout, pos: Vector3): boolean
	local s = LevelBuilder.CELL
	return pos.X >= 0 and pos.Z >= 0 and pos.X <= layout.width * s and pos.Z <= layout.depth * s and pos.Y > -20
end

-- World position of the middle of a cell, at floor height.
function LevelBuilder.cellCenter(x: number, z: number): Vector3
	local s = LevelBuilder.CELL
	return Vector3.new((x - 0.5) * s, 0, (z - 0.5) * s)
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
	prop({ Name = "ChairSeat", Size = Vector3.new(1.7, 0.3, 1.7), CFrame = base * CFrame.new(0, 1.6, 0), Color = FABRIC_BLUE, Material = Enum.Material.Fabric }, parent)
	prop({ Name = "ChairBack", Size = Vector3.new(1.7, 1.9, 0.25), CFrame = base * CFrame.new(0, 2.7, 0.8) * CFrame.Angles(math.rad(-8), 0, 0), Color = FABRIC_BLUE, Material = Enum.Material.Fabric }, parent)
	detail({ Name = "ChairPost", Size = Vector3.new(0.22, 1.4, 0.22), CFrame = base * CFrame.new(0, 0.8, 0), Color = DARK, Material = Enum.Material.Metal }, parent)
	detail({ Name = "ChairFoot", Size = Vector3.new(1.5, 0.15, 1.5), CFrame = base * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(45), 0), Color = DARK, Material = Enum.Material.Metal }, parent)
end

local function desk(parent: Instance, at: CFrame, h: (number) -> number)
	prop({ Name = "DeskTop", Size = Vector3.new(5.2, 0.25, 2.6), CFrame = at * CFrame.new(0, 2.6, 0), Color = WOOD, Material = Enum.Material.WoodPlanks }, parent)
	for _, side in { -1, 1 } do
		prop({ Name = "DeskSide", Size = Vector3.new(0.2, 2.5, 2.5), CFrame = at * CFrame.new(side * 2.45, 1.25, 0), Color = GREY_METAL, Material = Enum.Material.Metal }, parent)
	end
	detail({ Name = "DeskPanel", Size = Vector3.new(4.7, 1.4, 0.12), CFrame = at * CFrame.new(0, 1.7, -1.15), Color = GREY_METAL, Material = Enum.Material.Metal }, parent)
	if h(1) < 0.75 then
		-- An old CRT-ish monitor, left on its stand or knocked over.
		local fallen = h(2) < 0.2
		local m = if fallen then at * CFrame.new(0.4, 2.9, -0.2) * CFrame.Angles(math.rad(-90), 0, 0) else at * CFrame.new(0.4, 3.55, -0.6)
		detail({ Name = "Monitor", Size = Vector3.new(1.7, 1.25, 1.1), CFrame = m, Color = Color3.fromRGB(196, 190, 172), Material = Enum.Material.SmoothPlastic }, parent)
		detail({ Name = "Screen", Size = Vector3.new(1.4, 0.95, 0.05), CFrame = m * CFrame.new(0, 0, 0.56), Color = Color3.fromRGB(24, 28, 26), Material = Enum.Material.Glass, Reflectance = 0.15 }, parent)
	end
	if h(3) < 0.6 then
		detail({ Name = "Keyboard", Size = Vector3.new(1.5, 0.08, 0.5), CFrame = at * CFrame.new(0.4, 2.77, 0.5) * CFrame.Angles(0, math.rad((h(4) - 0.5) * 30), 0), Color = Color3.fromRGB(186, 180, 162), Material = Enum.Material.SmoothPlastic }, parent)
	end
	-- Paper left lying around.
	for i = 1, math.floor(h(5) * 4) do
		detail({ Name = "Paper", Size = Vector3.new(0.85, 0.02, 1.1), CFrame = at * CFrame.new((h(10 + i) - 0.5) * 7, 0.02, (h(20 + i) - 0.5) * 6) * CFrame.Angles(0, h(30 + i) * 6.28, 0), Color = PAPER, Material = Enum.Material.SmoothPlastic }, parent)
	end
	chair(parent, at * CFrame.new((h(6) - 0.5) * 1.5, 0, 2.2 + h(7)) * CFrame.Angles(0, (h(8) - 0.5) * 1.6, 0), h(9) < 0.15)
end

local function filingCabinet(parent: Instance, at: CFrame)
	prop({ Name = "Cabinet", Size = Vector3.new(1.8, 4.4, 2.2), CFrame = at * CFrame.new(0, 2.2, 0), Color = Color3.fromRGB(140, 138, 126), Material = Enum.Material.Metal }, parent)
	for i = 0, 3 do
		detail({ Name = "DrawerLine", Size = Vector3.new(1.6, 0.05, 0.04), CFrame = at * CFrame.new(0, 0.6 + i * 1.05, -1.11), Color = DARK, Material = Enum.Material.Metal }, parent)
		detail({ Name = "Handle", Size = Vector3.new(0.5, 0.1, 0.1), CFrame = at * CFrame.new(0, 0.95 + i * 1.05, -1.14), Color = Color3.fromRGB(180, 178, 170), Material = Enum.Material.Metal }, parent)
	end
end

local function box(parent: Instance, cf: CFrame, size: Vector3)
	prop({ Name = "Box", Size = size, CFrame = cf * CFrame.new(0, size.Y / 2, 0), Color = CARDBOARD, Material = Enum.Material.Cardboard }, parent)
	detail({ Name = "Tape", Size = Vector3.new(size.X + 0.02, 0.02, 0.35), CFrame = cf * CFrame.new(0, size.Y + 0.01, 0), Color = Color3.fromRGB(190, 170, 120), Material = Enum.Material.SmoothPlastic }, parent)
end

local function shelving(parent: Instance, at: CFrame, h: (number) -> number)
	local W, Dp, Ht = 8, 2.4, 7.4
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			prop({ Name = "Upright", Size = Vector3.new(0.25, Ht, 0.25), CFrame = at * CFrame.new(sx * W / 2, Ht / 2, sz * Dp / 2), Color = Color3.fromRGB(70, 96, 140), Material = Enum.Material.Metal }, parent)
		end
	end
	for level = 0, 3 do
		local y = 0.4 + level * 2.2
		prop({ Name = "Shelf", Size = Vector3.new(W, 0.15, Dp), CFrame = at * CFrame.new(0, y, 0), Color = GREY_METAL, Material = Enum.Material.DiamondPlate }, parent)
		-- Boxes on the shelf (not all of them full).
		local x = -W / 2 + 0.3
		local i = 0
		while x < W / 2 - 1.2 do
			i += 1
			local bw = 1.2 + h(level * 10 + i) * 1.4
			if h(level * 10 + i + 50) < 0.7 and x + bw < W / 2 then
				local bh = math.min(1.9, 0.8 + h(level * 10 + i + 90) * 1.2)
				box(parent, at * CFrame.new(x + bw / 2, y + 0.08, (h(i + 7) - 0.5) * 0.3) * CFrame.Angles(0, (h(i + 3) - 0.5) * 0.3, 0), Vector3.new(bw, bh, Dp - 0.5))
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

-- Dresses one cell of a set piece.
local function dressCell(parent: Instance, kind: string, room: LevelGen.Room, x: number, z: number, seed: number)
	local function h(n: number): number
		return hash(x * 7 + n, z * 13 - n, n * 3.1, seed)
	end
	local c = LevelBuilder.cellCenter(x, z)
	local yaw = math.floor(h(0) * 4) * math.rad(90) + (h(99) - 0.5) * 0.12
	local at = CFrame.new(c) * CFrame.Angles(0, yaw, 0)
	if kind == "office" then
		desk(parent, at * CFrame.new((h(41) - 0.5) * 4, 0, (h(42) - 0.5) * 4), h)
		if h(43) < 0.35 then
			filingCabinet(parent, at * CFrame.new(7, 0, (h(44) - 0.5) * 10) * CFrame.Angles(0, math.rad(90), 0))
		end
	elseif kind == "storage" then
		-- Racks in rows along the room's long side.
		local alongX = room.w >= room.d
		local rackYaw = if alongX then 0 else math.rad(90)
		shelving(parent, CFrame.new(c) * CFrame.Angles(0, rackYaw, 0) * CFrame.new(0, 0, -4), h)
		if h(45) < 0.5 then
			box(parent, CFrame.new(c) * CFrame.Angles(0, rackYaw + (h(46) - 0.5), 0) * CFrame.new((h(47) - 0.5) * 8, 0, 4.5), Vector3.new(2, 1.6, 2))
		end
	elseif kind == "atrium" then
		if h(48) < 0.3 then
			puddle(parent, CFrame.new(c + Vector3.new((h(49) - 0.5) * 12, 0, (h(50) - 0.5) * 12)), 4 + h(51) * 6)
		end
	elseif kind == "room" then
		local roll = h(52)
		if roll < 0.18 then
			local base = at * CFrame.new((h(53) - 0.5) * 10, 0, (h(54) - 0.5) * 10)
			box(parent, base, Vector3.new(2.2, 1.8, 2.2))
			if h(55) < 0.6 then
				box(parent, base * CFrame.new(0.1, 1.8, -0.1) * CFrame.Angles(0, 0.3, 0), Vector3.new(1.8, 1.4, 1.8))
			end
		elseif roll < 0.3 then
			chair(parent, at * CFrame.new((h(56) - 0.5) * 10, 0, (h(57) - 0.5) * 10), h(58) < 0.3)
		elseif roll < 0.38 then
			puddle(parent, CFrame.new(c + Vector3.new((h(59) - 0.5) * 10, 0, (h(60) - 0.5) * 10)), 3 + h(61) * 4)
		end
	elseif kind == "hall" then
		if h(62) < 0.07 then
			chair(parent, at * CFrame.new(0, 0, (h(63) - 0.5) * 12), h(64) < 0.5)
		end
	else -- plain corridor
		local roll = h(65)
		if roll < 0.03 then
			box(parent, at * CFrame.new(6, 0, (h(66) - 0.5) * 10), Vector3.new(2, 1.6, 2))
		elseif roll < 0.045 then
			chair(parent, at * CFrame.new(5, 0, (h(67) - 0.5) * 10), true)
		end
	end
end

-- STRUCTURE (rebuilt by the Shift) --------------------------------------------

local panelsByModel: { [Instance]: { [number]: BasePart } } = setmetatable({}, { __mode = "k" }) :: any

-- Switches each fitting to match its cell's light state ("on", "flicker",
-- "dead"). The server only sets the LightState attribute and the tags;
-- each device does the visuals (main.client), so a Shift can't flash
-- lights on in the middle of its blackout. Tags: LightFitting (every
-- panel), CeilingLight (working, blacked out by the Shift), FlickerLight
-- (stutters, and where Lampjaw hides).
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
					panel.Material = if dead then Enum.Material.SmoothPlastic else Enum.Material.Neon
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
		detail({
			Name = "Skirting",
			Size = Vector3.new(T + 0.3, 0.7, (z1 - z0 + 1) * S + T + 0.3),
			Position = Vector3.new(xLine * S, 0.35, ((z0 - 1) * S + z1 * S) / 2),
			Color = COLORS.skirting,
			Material = MATERIALS.trim,
		}, walls)
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
		detail({
			Name = "Skirting",
			Size = Vector3.new((x1 - x0 + 1) * S + T + 0.3, 0.7, T + 0.3),
			Position = Vector3.new(((x0 - 1) * S + x1 * S) / 2, 0.35, zLine * S),
			Color = COLORS.skirting,
			Material = MATERIALS.trim,
		}, walls)
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
			detail({ Name = "Outlet", Size = Vector3.new(0.55, 0.85, 0.08), CFrame = frame * CFrame.new(along, 1.4, -0.04), Color = Color3.fromRGB(226, 220, 200), Material = Enum.Material.SmoothPlastic }, details)
			for _, dy in { 0.18, -0.18 } do
				detail({ Name = "Socket", Size = Vector3.new(0.22, 0.14, 0.04), CFrame = frame * CFrame.new(along, 1.4 + dy, -0.09), Color = DARK, Material = Enum.Material.SmoothPlastic }, details)
			end
		end
		if h(3) < 0.035 then
			local vy = H - 1.3
			detail({ Name = "VentFrame", Size = Vector3.new(2.6, 1.3, 0.1), CFrame = frame * CFrame.new(-along * 0.5, vy, -0.05), Color = Color3.fromRGB(176, 172, 160), Material = Enum.Material.Metal }, details)
			detail({ Name = "VentGrille", Size = Vector3.new(2.2, 0.95, 0.06), CFrame = frame * CFrame.new(-along * 0.5, vy, -0.1), Color = Color3.fromRGB(40, 38, 34), Material = Enum.Material.DiamondPlate }, details)
		end
		if h(4) < 0.09 then
			local sw, sh = 1.5 + h(5) * 4, 2 + h(6) * 5
			detail({
				Name = "WaterStain",
				Size = Vector3.new(sw, sh, 0.04),
				CFrame = frame * CFrame.new((h(7) - 0.5) * (S - sw - 2), H - sh / 2, -0.03),
				Color = COLORS.stain,
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.55 + h(8) * 0.25,
			}, details)
			-- A darker tide line where the water stopped.
			detail({
				Name = "StainEdge",
				Size = Vector3.new(sw * 0.8, 0.25, 0.04),
				CFrame = frame * CFrame.new((h(7) - 0.5) * (S - sw - 2), H - sh + 0.15, -0.035),
				Color = COLORS.stain:Lerp(Color3.new(0, 0, 0), 0.3),
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.5,
			}, details)
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
	-- rooms rather than gaps. 6 studs wide, 8 tall.
	local DOOR_W, DOOR_H = 6, 8
	local function doorway(mid: Vector3, alongX: boolean)
		local stub = (S - DOOR_W) / 2
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
			detail({
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
		detail({
			Name = "DoorLintel",
			Size = if alongX then Vector3.new(DOOR_W + 0.7, 0.35, T + 0.4) else Vector3.new(T + 0.4, 0.35, DOOR_W + 0.7),
			Position = mid + Vector3.new(0, DOOR_H + 0.17, 0),
			Color = COLORS.skirting,
			Material = Enum.Material.Wood,
		}, details)
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
				doorway(Vector3.new(x * S, 0, (z - 0.5) * S), false)
			end
			if z < D and not cells[x][z].wallSouth and needsDoor(here, roomAt[x * 1000 + z + 1]) then
				doorway(Vector3.new((x - 0.5) * S, 0, z * S), true)
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
				detail({ Name = "PillarBase", Size = Vector3.new(2.8, 0.7, 2.8), Position = Vector3.new(x * S, 0.35, z * S), Color = COLORS.skirting, Material = MATERIALS.trim }, walls)
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

	structure.Parent = model
	LevelBuilder.applyLights(layout, model)
end

-- STATIC LAYER -----------------------------------------------------------------

function LevelBuilder.build(layout: LevelGen.Layout, parent: Instance): Model
	local S, H, T = LevelBuilder.CELL, LevelBuilder.HEIGHT, LevelBuilder.THICK
	local W, D = layout.width, layout.depth
	local seed = layout.seed

	local model = Instance.new("Model")
	model.Name = "Level"
	model:SetAttribute("Seed", layout.seed)

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
	for i = 0, math.floor(W * S / step) do
		detail({ Name = "GridX", Size = Vector3.new(0.25, 0.1, D * S), Position = Vector3.new(i * step, H - 0.05, D * S / 2), Color = COLORS.grid, Material = MATERIALS.trim }, ceilingFolder)
	end
	for i = 0, math.floor(D * S / step) do
		detail({ Name = "GridZ", Size = Vector3.new(W * S, 0.1, 0.25), Position = Vector3.new(W * S / 2, H - 0.05, i * step), Color = COLORS.grid, Material = MATERIALS.trim }, ceilingFolder)
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
			-- that isn't where the light fitting hangs.
			local tx, tz = math.floor(h(1) * 4), math.floor(h(2) * 4)
			local tile = Vector3.new(c.X - S / 2 + (tx + 0.5) * step, H - 0.03, c.Z - S / 2 + (tz + 0.5) * step)
			local onLight = (tx == 1 or tx == 2) and (tz == 1 or tz == 2)
			if not onLight then
				local roll = h(3)
				if roll < 0.05 then
					-- Missing tile: a black hole into the ceiling void.
					detail({ Name = "MissingTile", Size = Vector3.new(step - 0.3, 0.04, step - 0.3), Position = tile, Color = Color3.fromRGB(8, 8, 8), Material = Enum.Material.SmoothPlastic }, damage)
				elseif roll < 0.2 then
					detail({ Name = "StainedTile", Size = Vector3.new(step - 0.3, 0.04, step - 0.3), Position = tile, Color = COLORS.ceiling:Lerp(COLORS.stain, 0.35 + h(4) * 0.3), Material = MATERIALS.ceiling }, damage)
				end
			end
			if h(5) < 0.1 then
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
			detail({ Name = "LightHousing", Size = Vector3.new(5, 0.3, 2.8), Position = Vector3.new(c.X, H - 0.15, c.Z), Color = COLORS.housing, Material = Enum.Material.Metal }, lights)
			local panel = detail({ Name = "LightPanel", Size = Vector3.new(4.4, 0.1, 2.2), Position = Vector3.new(c.X, H - 0.33, c.Z), Color = COLORS.lightOn, Material = Enum.Material.Neon }, lights)
			detail({ Name = "LightBar", Size = Vector3.new(4.4, 0.08, 0.18), Position = Vector3.new(c.X, H - 0.4, c.Z), Color = COLORS.housing, Material = Enum.Material.Metal }, lights)
			local light = Instance.new("SurfaceLight")
			light.Face = Enum.NormalId.Bottom
			light.Angle = 120
			light.Range = 20
			light.Brightness = 2
			light.Color = COLORS.lightOn
			light.Shadows = false -- shadows on ~900 lights would kill phones
			light.Parent = panel
			panel:SetAttribute("Cell", x * 1000 + z) -- lets entities find "the light over this cell"
			panels[x * 1000 + z] = panel
		end
	end
	panelsByModel[model] = panels

	LevelBuilder.buildStructure(layout, model)

	-- If the place uses StreamingEnabled (new places do by default), parts
	-- only reach players gradually, so walls and lights could pop in.
	-- Persistent sends the whole level to everyone up front.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	model.Parent = parent
	return model
end

return LevelBuilder
