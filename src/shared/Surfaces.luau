--!strict
-- Surfaces: SHIFT's PBR materials. Every texture set in assets/textures
-- becomes:
--   * a MaterialVariant in MaterialService (ColorMap, NormalMap,
--     RoughnessMap, MetalnessMap) for ordinary Parts, and
--   * a SurfaceAppearance template in ReplicatedStorage.SHIFT_Surfaces for
--     MeshParts (imported entity meshes, props).
-- The IDs come from AssetIds.luau (tools/upload_assets.py writes it).
--
-- Until a set is uploaded its surfaces use a built-in fallback material,
-- never SmoothPlastic. Once uploaded, the server installs everything on
-- start. Roblox may block scripts from setting texture maps while the
-- game runs; if so, Output says so and one line in Studio's command bar
-- installs them into the place for good (then save the place):
--     require(game.ReplicatedStorage.Shared.Surfaces).install()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetIds = require(script.Parent:WaitForChild("AssetIds"))

local Surfaces = {}

export type Spec = {
	set: string, -- texture set in AssetIds.textures / assets/textures
	base: string, -- the built-in material the variant sits on (footsteps, physics)
	fallback: string, -- what to use until it's uploaded
	studs: number, -- studs per texture tile
	tint: boolean, -- true: neutral texture, the part's Color tints it; false: the texture has its own colour
}

Surfaces.SPECS = {
	SHIFT_Wallpaper = { set = "wallpaper", base = "Plaster", fallback = "Plaster", studs = 8, tint = false },
	SHIFT_Carpet = { set = "carpet", base = "Carpet", fallback = "Carpet", studs = 10, tint = false },
	SHIFT_CeilingTile = { set = "ceiling", base = "Plaster", fallback = "Plaster", studs = 10, tint = false },
	SHIFT_Concrete = { set = "concrete", base = "Concrete", fallback = "Concrete", studs = 14, tint = false },
	SHIFT_WardTile = { set = "ward_tile", base = "CeramicTiles", fallback = "Marble", studs = 8, tint = false },
	SHIFT_WardFloor = { set = "ward_floor", base = "Slate", fallback = "Slate", studs = 16, tint = false },
	SHIFT_SteelPlate = { set = "steel_plate", base = "DiamondPlate", fallback = "DiamondPlate", studs = 10, tint = false },
	SHIFT_PaintedMetal = { set = "painted_metal", base = "Metal", fallback = "Metal", studs = 6, tint = true },
	SHIFT_BrushedMetal = { set = "brushed_metal", base = "Metal", fallback = "Metal", studs = 6, tint = true },
	SHIFT_Rust = { set = "rust", base = "CorrodedMetal", fallback = "CorrodedMetal", studs = 8, tint = false },
	SHIFT_Wood = { set = "wood", base = "Wood", fallback = "Wood", studs = 6, tint = false },
	SHIFT_Fabric = { set = "fabric", base = "Fabric", fallback = "Fabric", studs = 3, tint = true },
	SHIFT_Cardboard = { set = "cardboard", base = "Cardboard", fallback = "Cardboard", studs = 4, tint = false },
	SHIFT_AgedPlastic = { set = "aged_plastic", base = "Plastic", fallback = "Plastic", studs = 3, tint = true },
	SHIFT_Paper = { set = "paper", base = "Fabric", fallback = "Fabric", studs = 1.2, tint = false },
	SHIFT_Rubber = { set = "rubber", base = "Rubber", fallback = "Rubber", studs = 3, tint = false },
	SHIFT_SuitFabric = { set = "suit_fabric", base = "Fabric", fallback = "Fabric", studs = 3, tint = true },
	SHIFT_TenantSkin = { set = "tenant_skin", base = "Rubber", fallback = "Rubber", studs = 3, tint = false },
	SHIFT_TenantCoat = { set = "tenant_coat", base = "Fabric", fallback = "Fabric", studs = 4, tint = false },
} :: { [string]: Spec }

-- Built-in material -> the variant that dresses it (Surfaces.auto).
local BY_MATERIAL: { [string]: string } = {
	Metal = "SHIFT_PaintedMetal",
	DiamondPlate = "SHIFT_SteelPlate",
	CorrodedMetal = "SHIFT_Rust",
	Wood = "SHIFT_Wood",
	WoodPlanks = "SHIFT_Wood",
	Fabric = "SHIFT_Fabric",
	Cardboard = "SHIFT_Cardboard",
	Plastic = "SHIFT_AgedPlastic",
	SmoothPlastic = "SHIFT_AgedPlastic",
	Concrete = "SHIFT_Concrete",
	Rubber = "SHIFT_Rubber",
	Leather = "SHIFT_Rubber",
	Carpet = "SHIFT_Carpet",
}
-- Some parts are better matched by name.
local BY_NAME: { [string]: string } = {
	Paper = "SHIFT_Paper",
	LightHousing = "SHIFT_BrushedMetal",
	LightBar = "SHIFT_BrushedMetal",
	Handle = "SHIFT_BrushedMetal",
	ChairPost = "SHIFT_BrushedMetal",
	ChairFoot = "SHIFT_BrushedMetal",
}

local function material(name: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	return if ok and m then m else Enum.Material.Plastic
end

local function texturesFor(set: string): { [string]: string }?
	local ids = (AssetIds.textures :: any)[set]
	if not ids or (ids.colour or "") == "" then
		return nil
	end
	return ids
end

-- "123" / "rbxassetid://123" / "decal:123" -> a usable image URL.
-- Decal IDs (what Roblox gives you for an uploaded image) are turned into
-- the image behind them, which only the server (or Studio) can look up.
local resolved: { [string]: string } = {}
function Surfaces.image(id: string?): string
	if not id or id == "" then
		return ""
	end
	if resolved[id] then
		return resolved[id]
	end
	local out = id
	local decal = string.match(id, "^decal:(%d+)$")
	if decal then
		out = `rbxassetid://{decal}`
		if RunService:IsServer() or not RunService:IsRunning() then
			local ok, model = pcall(function()
				return game:GetService("InsertService"):LoadAsset(tonumber(decal) :: number)
			end)
			if ok and model then
				local d = model:FindFirstChildWhichIsA("Decal", true)
				if d and d.Texture ~= "" then
					out = d.Texture
				end
				model:Destroy()
			end
		end
	elseif string.match(id, "^%d+$") then
		out = `rbxassetid://{id}`
	end
	resolved[id] = out
	return out
end

local available: { [string]: boolean } = {}

local function setMaps(target: Instance, ids: { [string]: string }): boolean
	return pcall(function()
		local t = target :: any
		t.ColorMap = Surfaces.image(ids.colour)
		t.NormalMap = Surfaces.image(ids.normal)
		t.RoughnessMap = Surfaces.image(ids.roughness)
		t.MetalnessMap = Surfaces.image(ids.metalness)
	end)
end

-- Make (or update) every uploaded set's MaterialVariant and SurfaceAppearance.
-- Safe to call again; runs on the server at start, or from Studio's
-- command bar (which is allowed to set texture maps and saves them into
-- the place).
function Surfaces.install(): (number, number)
	local MaterialService = game:GetService("MaterialService")
	local templates = ReplicatedStorage:FindFirstChild("SHIFT_Surfaces")
	if not templates then
		templates = Instance.new("Folder")
		templates.Name = "SHIFT_Surfaces"
		templates.Parent = ReplicatedStorage
	end
	local made, blocked = 0, 0
	-- Look decal IDs up in parallel: each lookup can take a moment.
	local pending = 0
	for _, spec in Surfaces.SPECS do
		local ids = texturesFor(spec.set)
		if ids then
			for _, id in ids do
				if string.sub(id, 1, 6) == "decal:" and not resolved[id] then
					pending += 1
					task.spawn(function()
						Surfaces.image(id)
						pending -= 1
					end)
				end
			end
		end
	end
	local deadline = os.clock() + 20
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end

	for name, spec in Surfaces.SPECS do
		local ids = texturesFor(spec.set)
		if not ids then
			continue
		end
		local v = MaterialService:FindFirstChild(name)
		if not (v and v:IsA("MaterialVariant")) then
			v = Instance.new("MaterialVariant")
			v.Name = name
		end
		local variant = v :: MaterialVariant
		variant.BaseMaterial = material(spec.base)
		variant.StudsPerTile = spec.studs
		if setMaps(variant, ids) then
			variant.Parent = MaterialService
			made += 1
		elseif variant.Parent == MaterialService and variant.ColorMap ~= "" then
			made += 1 -- installed earlier from the command bar
		else
			blocked += 1
		end
		local sa = templates:FindFirstChild(name)
		if not (sa and sa:IsA("SurfaceAppearance")) then
			sa = Instance.new("SurfaceAppearance")
			sa.Name = name
		end
		if setMaps(sa :: SurfaceAppearance, ids) then
			(sa :: SurfaceAppearance).Parent = templates
		end
	end
	Surfaces.refresh()
	return made, blocked
end

-- Re-check which variants exist (after install, or after they replicate).
function Surfaces.refresh()
	local MaterialService = game:GetService("MaterialService")
	for name in Surfaces.SPECS do
		local v = MaterialService:FindFirstChild(name)
		available[name] = v ~= nil and v:IsA("MaterialVariant") and v.ColorMap ~= ""
	end
end

function Surfaces.has(name: string): boolean
	return available[name] == true
end

-- Dress a part in a named surface: the textured variant when it's
-- uploaded, the built-in fallback until then.
function Surfaces.apply(part: BasePart, name: string)
	local spec = Surfaces.SPECS[name]
	if not spec then
		return
	end
	if available[name] then
		part.Material = material(spec.base)
		part.MaterialVariant = name
		if not spec.tint then
			part.Color = Color3.new(1, 1, 1) -- the texture brings its own colour
		end
	else
		part.Material = material(spec.fallback)
		part.MaterialVariant = ""
	end
end

-- Pick a surface from what the part already is (its material or name).
-- Lights (Neon), glass and invisible parts are left alone. Never leaves
-- SmoothPlastic behind.
function Surfaces.auto(part: BasePart)
	local m = part.Material
	if m == Enum.Material.Neon or m == Enum.Material.Glass or m == Enum.Material.ForceField or part.Transparency >= 1 then
		return
	end
	local name = BY_NAME[part.Name] or BY_MATERIAL[m.Name]
	if name then
		Surfaces.apply(part, name)
	elseif m == Enum.Material.SmoothPlastic then
		part.Material = Enum.Material.Plastic
	end
end

-- Every part under a model (props, the safehouse, the lift).
function Surfaces.autoAll(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			Surfaces.auto(d)
		end
	end
end

-- MeshParts get a SurfaceAppearance (all four maps) when it's uploaded,
-- otherwise the MaterialVariant (which works on MeshParts too).
function Surfaces.applyMesh(part: MeshPart, name: string)
	local templates = ReplicatedStorage:FindFirstChild("SHIFT_Surfaces")
	local sa = templates and templates:FindFirstChild(name)
	if sa and sa:IsA("SurfaceAppearance") and sa.ColorMap ~= "" then
		local old = part:FindFirstChildOfClass("SurfaceAppearance")
		if old then
			old:Destroy()
		end
		sa:Clone().Parent = part
	else
		Surfaces.apply(part, name)
	end
end

-- Server start: install what's uploaded and report.
function Surfaces.init()
	local total = 0
	for _, spec in Surfaces.SPECS do
		if texturesFor(spec.set) then
			total += 1
		end
	end
	local made, blocked = Surfaces.install()
	local count = 0
	for _ in Surfaces.SPECS do
		count += 1
	end
	if total == 0 then
		print(`[Surfaces] 0 of {count} PBR sets uploaded: built-in materials until then (TODO.md, "Uploads")`)
	elseif blocked > 0 and made == 0 then
		warn(`[Surfaces] {total} sets uploaded but Roblox blocked setting texture maps while running. In Studio (not playing), paste this in View > Command Bar and press Enter, then save the place:  require(game.ReplicatedStorage.Shared.Surfaces).install()`)
	else
		print(`[Surfaces] {made} of {count} PBR sets active`)
	end
end

return Surfaces
