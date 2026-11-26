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
	wall = Color3.fromRGB(196, 178, 104), -- stained yellow wallpaper
	carpet = Color3.fromRGB(140, 122, 68), -- damp carpet
	ceiling = Color3.fromRGB(214, 210, 188), -- office ceiling tiles
	lightOn = Color3.fromRGB(255, 244, 214),
	lightDead = Color3.fromRGB(70, 68, 60),
	pillar = Color3.fromRGB(180, 162, 92),
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
function LevelBuilder.cellCenter(x: number, z: number): Vector3
	local s = LevelBuilder.CELL
	return Vector3.new((x - 0.5) * s, 0, (z - 0.5) * s)
end

function LevelBuilder.build(layout: LevelGen.Layout, parent: Instance): Model
	local S, H, T = LevelBuilder.CELL, LevelBuilder.HEIGHT, LevelBuilder.THICK
	local W, D = layout.width, layout.depth

	local model = Instance.new("Model")
	model.Name = "Level"
	model:SetAttribute("Seed", layout.seed)

	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	walls.Parent = model
	local lights = Instance.new("Folder")
	lights.Name = "Lights"
	lights.Parent = model

	-- Floor and ceiling: one big slab each.
	makePart({
		Name = "Floor",
		Size = Vector3.new(W * S + T, 1, D * S + T),
		Position = Vector3.new(W * S / 2, -0.5, D * S / 2),
		Color = COLORS.carpet,
		Material = Enum.Material.Fabric,
	}, model)
	makePart({
		Name = "Ceiling",
		Size = Vector3.new(W * S + T, 1, D * S + T),
		Position = Vector3.new(W * S / 2, H + 0.5, D * S / 2),
		Color = COLORS.ceiling,
		Material = Enum.Material.Concrete,
	}, model)

	local function wallX(xLine: number, z0: number, z1: number)
		-- Wall running north-south along X = xLine * S, covering cells z0..z1.
		makePart({
			Name = "Wall",
			Size = Vector3.new(T, H, (z1 - z0 + 1) * S + T),
			Position = Vector3.new(xLine * S, H / 2, ((z0 - 1) * S + z1 * S) / 2),
			Color = COLORS.wall,
			Material = Enum.Material.SmoothPlastic,
		}, walls)
	end
	local function wallZ(zLine: number, x0: number, x1: number)
		-- Wall running east-west along Z = zLine * S, covering cells x0..x1.
		makePart({
			Name = "Wall",
			Size = Vector3.new((x1 - x0 + 1) * S + T, H, T),
			Position = Vector3.new(((x0 - 1) * S + x1 * S) / 2, H / 2, zLine * S),
			Color = COLORS.wall,
			Material = Enum.Material.SmoothPlastic,
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
	local pillarAt: { [number]: boolean } = {} -- rooms can overlap; one pillar per spot
	for _, room in layout.rooms do
		for x = room.x, room.x + room.w - 2 do
			for z = room.z, room.z + room.d - 2 do
				if pillarAt[x * 1000 + z] then
					continue
				end
				pillarAt[x * 1000 + z] = true
				makePart({
					Name = "Pillar",
					Size = Vector3.new(2, H, 2),
					Position = Vector3.new(x * S, H / 2, z * S),
					Color = COLORS.pillar,
					Material = Enum.Material.SmoothPlastic,
				}, walls)
			end
		end
	end

	-- One ceiling light panel per cell.
	for x = 1, W do
		for z = 1, D do
			local cell = layout.cells[x][z]
			local c = LevelBuilder.cellCenter(x, z)
			local dead = cell.light == "dead"
			local panel = makePart({
				Name = "LightPanel",
				Size = Vector3.new(4, 0.2, 2),
				Position = Vector3.new(c.X, H - 0.1, c.Z),
				Color = if dead then COLORS.lightDead else COLORS.lightOn,
				Material = if dead then Enum.Material.SmoothPlastic else Enum.Material.Neon,
				CanCollide = false,
				CastShadow = false,
			}, lights)
			if not dead then
				local light = Instance.new("SurfaceLight")
				light.Face = Enum.NormalId.Bottom
				light.Angle = 120
				light.Range = 18
				light.Brightness = 1.6
				light.Color = COLORS.lightOn
				light.Shadows = false -- shadows on 196 lights would kill phones
				light.Parent = panel
			end
			if cell.light == "flicker" then
				CollectionService:AddTag(panel, "FlickerLight")
			end
		end
	end

	model.Parent = parent
	return model
end

return LevelBuilder
