--!strict
-- LevelBuilder: turns a LevelGen layout into grey-box parts in Workspace.
-- Walls along the same line are merged into one long part to keep
-- the part count (and server cost) low.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelGen = require(ReplicatedStorage.Shared.LevelGen)

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
}

-- Built-in Roblox materials only (no uploads needed).
local MATERIALS = {
	wall = Enum.Material.Plaster,
	carpet = Enum.Material.Carpet,
	ceiling = Enum.Material.Plaster,
	trim = Enum.Material.SmoothPlastic,
}

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

-- World position of the middle of a cell, at floor height.
-- Is this position inside the level (not the safehouse)?
function LevelBuilder.inLevel(layout: LevelGen.Layout, pos: Vector3): boolean
	local s = LevelBuilder.CELL
	return pos.X >= 0 and pos.Z >= 0 and pos.X <= layout.width * s and pos.Z <= layout.depth * s and pos.Y > -20
end

function LevelBuilder.cellCenter(x: number, z: number): Vector3
	local s = LevelBuilder.CELL
	return Vector3.new((x - 0.5) * s, 0, (z - 0.5) * s)
end

-- Walls, skirting, pillars and light fittings: everything the Shift
-- changes. Lives in its own folder so it can be torn down and rebuilt.
function LevelBuilder.buildStructure(layout: LevelGen.Layout, model: Instance)
	local S, H, T = LevelBuilder.CELL, LevelBuilder.HEIGHT, LevelBuilder.THICK
	local W, D = layout.width, layout.depth

	local old = model:FindFirstChild("Structure")
	if old then
		old:Destroy()
	end
	local structure = Instance.new("Folder")
	structure.Name = "Structure"
	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	walls.Parent = structure
	local lights = Instance.new("Folder")
	lights.Name = "Lights"
	lights.Parent = structure

	-- Slightly different shade per wall run, so walls look patchy and aged
	-- rather than one flat colour. Seeded, so the same seed looks the same.
	-- The shade comes from the wall's position (not a running random number),
	-- so a wall that survives a Shift keeps exactly the same colour.
	local function agedWallColor(a: number, b: number): Color3
		local h = math.sin(a * 12.9898 + b * 78.233 + layout.seed * 0.001) * 43758.5453
		local shade = 0.86 + (h - math.floor(h)) * 0.16
		local c = COLORS.wall
		return Color3.new(c.R * shade, c.G * shade, c.B * (shade - 0.04))
	end

	local function wallX(xLine: number, z0: number, z1: number)
		-- Wall running north-south along X = xLine * S, covering cells z0..z1.
		makePart({
			Name = "Wall",
			Size = Vector3.new(T, H, (z1 - z0 + 1) * S + T),
			Position = Vector3.new(xLine * S, H / 2, ((z0 - 1) * S + z1 * S) / 2),
			Color = agedWallColor(xLine, z0),
			Material = MATERIALS.wall,
		}, walls)
		makePart({
			Name = "Skirting",
			Size = Vector3.new(T + 0.3, 0.7, (z1 - z0 + 1) * S + T + 0.3),
			Position = Vector3.new(xLine * S, 0.35, ((z0 - 1) * S + z1 * S) / 2),
			Color = COLORS.skirting,
			Material = MATERIALS.trim,
			CastShadow = false,
		}, walls)
	end
	local function wallZ(zLine: number, x0: number, x1: number)
		-- Wall running east-west along Z = zLine * S, covering cells x0..x1.
		makePart({
			Name = "Wall",
			Size = Vector3.new((x1 - x0 + 1) * S + T, H, T),
			Position = Vector3.new(((x0 - 1) * S + x1 * S) / 2, H / 2, zLine * S),
			Color = agedWallColor(x0 + 500, zLine),
			Material = MATERIALS.wall,
		}, walls)
		makePart({
			Name = "Skirting",
			Size = Vector3.new((x1 - x0 + 1) * S + T + 0.3, 0.7, T + 0.3),
			Position = Vector3.new(((x0 - 1) * S + x1 * S) / 2, 0.35, zLine * S),
			Color = COLORS.skirting,
			Material = MATERIALS.trim,
			CastShadow = false,
		}, walls)
	end

	-- Outer west and north border (east/south borders come from the cells).
	wallX(0, 1, D)
	wallZ(0, 1, W)

	-- East walls, merged into runs per column line.
	for x = 1, W do
		local runStart: number? = nil
		for z = 1, D + 1 do
			local present = z <= D and layout.cells[x][z].wallEast
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
			local present = x <= W and layout.cells[x][z].wallSouth
			if present and not runStart then
				runStart = x
			elseif not present and runStart then
				wallZ(z, runStart, x - 1)
				runStart = nil
			end
		end
	end

	-- Pillars inside rooms, at the inner grid corners, so rooms aren't empty boxes.
	-- Only where all four cells meeting at that corner are still room cells
	-- (a Shift can rewire half a room).
	local pillarAt: { [number]: boolean } = {} -- rooms can overlap; one pillar per spot
	local cells = layout.cells
	for _, room in layout.rooms do
		for x = room.x, room.x + room.w - 2 do
			for z = room.z, room.z + room.d - 2 do
				if pillarAt[x * 1000 + z] then
					continue
				end
				if not (cells[x][z].room and cells[x + 1][z].room and cells[x][z + 1].room and cells[x + 1][z + 1].room) then
					continue
				end
				pillarAt[x * 1000 + z] = true
				makePart({
					Name = "Pillar",
					Size = Vector3.new(2, H, 2),
					Position = Vector3.new(x * S, H / 2, z * S),
					Color = COLORS.pillar,
					Material = MATERIALS.wall,
				}, walls)
			end
		end
	end

	-- One fluorescent fitting per cell: a frame flush with the ceiling
	-- and a glowing diffuser panel just below it.
	for x = 1, W do
		for z = 1, D do
			local cell = layout.cells[x][z]
			local c = LevelBuilder.cellCenter(x, z)
			local dead = cell.light == "dead"
			makePart({
				Name = "LightHousing",
				Size = Vector3.new(4.6, 0.3, 2.6),
				Position = Vector3.new(c.X, H - 0.15, c.Z),
				Color = COLORS.housing,
				Material = MATERIALS.trim,
				CanCollide = false,
				CastShadow = false,
			}, lights)
			local panel = makePart({
				Name = "LightPanel",
				Size = Vector3.new(4, 0.12, 2),
				Position = Vector3.new(c.X, H - 0.33, c.Z),
				Color = if dead then COLORS.lightDead else COLORS.lightOn,
				Material = if dead then Enum.Material.SmoothPlastic else Enum.Material.Neon,
				CanCollide = false,
				CastShadow = false,
			}, lights)
			if not dead then
				local light = Instance.new("SurfaceLight")
				light.Face = Enum.NormalId.Bottom
				light.Angle = 120
				light.Range = 20
				light.Brightness = 2
				light.Color = COLORS.lightOn
				light.Shadows = false -- shadows on 196 lights would kill phones
				light.Parent = panel
			end
			panel:SetAttribute("LightState", cell.light)
			panel:SetAttribute("Cell", x * 1000 + z) -- lets entities find "the light over this cell"
			if not dead then
				CollectionService:AddTag(panel, "CeilingLight") -- the Shift blacks these out
			end
			if cell.light == "flicker" then
				CollectionService:AddTag(panel, "FlickerLight")
			end
		end
	end

	structure.Parent = model
end

function LevelBuilder.build(layout: LevelGen.Layout, parent: Instance): Model
	local S, H, T = LevelBuilder.CELL, LevelBuilder.HEIGHT, LevelBuilder.THICK
	local W, D = layout.width, layout.depth

	local model = Instance.new("Model")
	model.Name = "Level"
	model:SetAttribute("Seed", layout.seed)

	-- Floor and ceiling: one big slab each.
	makePart({
		Name = "Floor",
		Size = Vector3.new(W * S + T, 1, D * S + T),
		Position = Vector3.new(W * S / 2, -0.5, D * S / 2),
		Color = COLORS.carpet,
		Material = MATERIALS.carpet,
	}, model)
	makePart({
		Name = "Ceiling",
		Size = Vector3.new(W * S + T, 1, D * S + T),
		Position = Vector3.new(W * S / 2, H + 0.5, D * S / 2),
		Color = COLORS.ceiling,
		Material = MATERIALS.ceiling,
	}, model)

	-- Suspended-ceiling grid: thin strips every quarter cell, both ways.
	local ceilingFolder = Instance.new("Folder")
	ceilingFolder.Name = "CeilingGrid"
	ceilingFolder.Parent = model
	local step = S / 4
	for i = 0, math.floor(W * S / step) do
		makePart({
			Name = "GridX",
			Size = Vector3.new(0.25, 0.1, D * S),
			Position = Vector3.new(i * step, H - 0.05, D * S / 2),
			Color = COLORS.grid,
			Material = MATERIALS.trim,
			CanCollide = false,
			CastShadow = false,
		}, ceilingFolder)
	end
	for i = 0, math.floor(D * S / step) do
		makePart({
			Name = "GridZ",
			Size = Vector3.new(W * S, 0.1, 0.25),
			Position = Vector3.new(W * S / 2, H - 0.05, i * step),
			Color = COLORS.grid,
			Material = MATERIALS.trim,
			CanCollide = false,
			CastShadow = false,
		}, ceilingFolder)
	end

	LevelBuilder.buildStructure(layout, model)

	-- If the place uses StreamingEnabled (new places do by default), parts
	-- only reach players gradually, so walls and lights could pop in over
	-- several seconds. Persistent sends the whole level to everyone up front.
	-- It's ~800 simple parts, so this is cheap.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	model.Parent = parent
	return model
end

return LevelBuilder
