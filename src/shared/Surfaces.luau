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
Surfaces.lastError = ""

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
		local function fromDecal(inst: Instance): string?
			local d = if inst:IsA("Decal") then inst else inst:FindFirstChildWhichIsA("Decal", true)
			return if d and (d :: Decal).Texture ~= "" then (d :: Decal).Texture else nil
		end
		local found: string? = nil
		if not RunService:IsRunning() then
			-- Studio command bar: GetObjects reads the decal straight away.
			local ok, objects = pcall(function()
				return (game :: any):GetObjects(`rbxassetid://{decal}`)
			end)
			if ok and objects then
				for _, o in objects do
					found = found or fromDecal(o)
					o:Destroy()
				end
			end
		end
		if not found and RunService:IsServer() then
			local ok, model = pcall(function()
				return game:GetService("InsertService"):LoadAsset(tonumber(decal) :: number)
			end)
			if ok and model then
				found = fromDecal(model)
				model:Destroy()
			end
		end
		if found then
			out = found
		else
			Surfaces.lastError = `couldn't look up the image behind decal {decal}`
		end
	elseif string.match(id, "^%d+$") then
		out = `rbxassetid://{id}`
	end
	resolved[id] = out
	return out
end

local available: { [string]: boolean } = {}

local function setMaps(target: Instance, ids: { [string]: string }): boolean
	local ok, err = pcall(function()
		local t = target :: any
		t.ColorMap = Surfaces.image(ids.colour)
		t.NormalMap = Surfaces.image(ids.normal)
		t.RoughnessMap = Surfaces.image(ids.roughness)
		t.MetalnessMap = Surfaces.image(ids.metalness)
	end)
	if not ok then
		Surfaces.lastError = tostring(err)
	end
	return ok
end

-- Does a MaterialVariant already carry its textures? (A running game may
-- not be allowed to read ColorMap; then being there at all counts.)
local function hasMaps(v: Instance): boolean
	local ok, colour = pcall(function()
		return (v :: any).ColorMap
	end)
	return not ok or (typeof(colour) == "string" and colour ~= "") or (ok and typeof(colour) ~= "string" and colour ~= nil)
end

-- Best lighting the place allows: shadows from every light (Future). A
-- running game can't change these; the command-bar install() can. Newer
-- Studios replace Technology with LightingStyle + PrioritizeLightingQuality,
-- which is why Technology may look locked; whichever exists is set.
function Surfaces.lighting(): string
	local Lighting = game:GetService("Lighting")
	local done = {}
	if pcall(function()
		(Lighting :: any).Technology = Enum.Technology.Future
	end) then
		table.insert(done, "Technology = Future")
	end
	if pcall(function()
		(Lighting :: any).LightingStyle = (Enum :: any).LightingStyle.Realistic
	end) then
		table.insert(done, "LightingStyle = Realistic")
	end
	if pcall(function()
		(Lighting :: any).PrioritizeLightingQuality = true
	end) then
		table.insert(done, "PrioritizeLightingQuality = on")
	end
	pcall(function()
		Lighting.GlobalShadows = true
	end)
	return if #done > 0 then table.concat(done, ", ") else "not allowed here"
end

-- Make (or update) every uploaded set's MaterialVariant and SurfaceAppearance.
-- Safe to call again; runs on the server at start, or from Studio's
-- command bar (which is allowed to set texture maps and saves them into
-- the place).
local function install(): (number, number)
	local MaterialService = game:GetService("MaterialService")
	if not RunService:IsRunning() then
		print(`[Surfaces] lighting: {Surfaces.lighting()}`)
	end
	local templates = ReplicatedStorage:FindFirstChild("SHIFT_Surfaces")
	if not templates then
		templates = Instance.new("Folder")
		templates.Name = "SHIFT_Surfaces"
		templates.Parent = ReplicatedStorage
	end
	local made, blocked = 0, 0
	local editing = not RunService:IsRunning()
	if editing then
		print("[Surfaces] installing SHIFT's PBR textures (a few seconds)...")
	else
		-- Look decal IDs up in parallel: each lookup can take a moment.
		local pending = 0
		for _, spec in Surfaces.SPECS do
			local ids = texturesFor(spec.set)
			if ids then
				for _, id in ids do
					if string.sub(id, 1, 6) == "decal:" and not resolved[id] then
						pending += 1
						task.spawn(function()
							pcall(Surfaces.image, id)
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
	end

	for name, spec in Surfaces.SPECS do
		local ids = texturesFor(spec.set)
		if not ids then
			continue
		end
		local v = MaterialService:FindFirstChild(name)
		local existing = v ~= nil and v:IsA("MaterialVariant") and hasMaps(v)
		if not (v and v:IsA("MaterialVariant")) then
			v = Instance.new("MaterialVariant")
			v.Name = name
		end
		local variant = v :: MaterialVariant
		-- A running game isn't allowed to set BaseMaterial or the texture
		-- maps (Plugin-only); the command bar is. So every write is guarded.
		local ok = pcall(function()
			variant.BaseMaterial = material(spec.base)
			variant.StudsPerTile = spec.studs
		end) and setMaps(variant, ids)
		if ok then
			variant.Parent = MaterialService
			made += 1
		elseif existing then
			made += 1 -- installed earlier from the command bar
		else
			blocked += 1
			if variant.Parent == nil then
				variant:Destroy()
			end
		end
		local sa = templates:FindFirstChild(name)
		if not (sa and sa:IsA("SurfaceAppearance")) then
			sa = Instance.new("SurfaceAppearance")
			sa.Name = name
		end
		if setMaps(sa :: SurfaceAppearance, ids) then
			(sa :: SurfaceAppearance).Parent = templates
		elseif (sa :: SurfaceAppearance).Parent == nil then
			sa:Destroy()
		end
	end
	Surfaces.refresh()
	if editing then
		local inService = 0
		for name in Surfaces.SPECS do
			local v = MaterialService:FindFirstChild(name)
			if v and v:IsA("MaterialVariant") then
				inService += 1
			end
		end
		if made > 0 then
			print(`[Surfaces] DONE: {made} PBR sets installed ({inService} SHIFT materials now in MaterialService). Now File > Save, then Play.`)
		else
			warn(`[Surfaces] FAILED: nothing installed. Reason: {Surfaces.lastError}. Send this line to Claude.`)
		end
	end
	return made, blocked
end

function Surfaces.install(): (number, number)
	if RunService:IsRunning() and RunService:IsClient() then
		warn("[Surfaces] stop the game first: this line only works in Studio while the game is NOT running.")
		return 0, 0
	end
	local ok, made, blocked = pcall(install)
	if not ok then
		warn(`[Surfaces] FAILED: {made}. Send this line to Claude.`)
		return 0, 0
	end
	return made, blocked
end

-- Re-check which variants exist (after install, or after they replicate).
function Surfaces.refresh()
	local MaterialService = game:GetService("MaterialService")
	for name in Surfaces.SPECS do
		local v = MaterialService:FindFirstChild(name)
		available[name] = v ~= nil and v:IsA("MaterialVariant") and hasMaps(v)
	end
end

-- FALLBACK WITHOUT THE COMMAND BAR ----------------------------------------------
-- Until the variants are installed, the big surfaces (walls, floors,
-- ceilings) still get the real texture: its colour map tiled over each
-- large face with Texture objects, which a running game IS allowed to
-- make. No normal or roughness maps, but real wallpaper, carpet and tile.
-- Server only (Textures replicate). Small props keep their material.

local colourUrl: { [string]: string } = {}
local waitingParts: { [BasePart]: string } = setmetatable({}, { __mode = "k" }) :: any
local preparing = false

local function bigFaces(part: BasePart): { Enum.NormalId }
	local x, y, z = part.Size.X, part.Size.Y, part.Size.Z
	local faces = {}
	local MIN = 4
	if x >= MIN and z >= MIN then
		table.insert(faces, Enum.NormalId.Top)
		table.insert(faces, Enum.NormalId.Bottom)
	end
	if x >= MIN and y >= MIN then
		table.insert(faces, Enum.NormalId.Front)
		table.insert(faces, Enum.NormalId.Back)
	end
	if z >= MIN and y >= MIN then
		table.insert(faces, Enum.NormalId.Left)
		table.insert(faces, Enum.NormalId.Right)
	end
	return faces
end

local function addTextures(part: BasePart, name: string, url: string)
	if part:FindFirstChild("SHIFT_Tex") then
		return
	end
	local spec = Surfaces.SPECS[name]
	for _, face in bigFaces(part) do
		local t = Instance.new("Texture")
		t.Name = "SHIFT_Tex"
		t.Face = face
		t.Texture = url
		t.StudsPerTileU = spec.studs
		t.StudsPerTileV = spec.studs
		t.Color3 = if spec.tint then part.Color else Color3.new(1, 1, 1)
		t.Parent = part
	end
end

-- Give a big part its surface's colour map now, or as soon as it's looked up.
function Surfaces.texture(part: BasePart, name: string)
	if available[name] or not RunService:IsServer() or not RunService:IsRunning() then
		return
	end
	local spec = Surfaces.SPECS[name]
	if not spec or not texturesFor(spec.set) or #bigFaces(part) == 0 then
		return
	end
	local url = colourUrl[name]
	if url then
		addTextures(part, name, url)
	else
		waitingParts[part] = name
	end
end

-- Look up every colour map in the background, then texture what's waiting.
function Surfaces.prepareTextures()
	if preparing then
		return
	end
	preparing = true
	task.spawn(function()
		local pending = 0
		for name, spec in Surfaces.SPECS do
			local ids = texturesFor(spec.set)
			if ids and not available[name] then
				pending += 1
				task.spawn(function()
					local ok, url = pcall(Surfaces.image, ids.colour)
					-- Only a real image: an unresolved decal ID would show nothing.
					local decal = string.match(ids.colour, "^decal:(%d+)$")
					if ok and url ~= "" and not (decal and url == `rbxassetid://{decal}`) then
						colourUrl[name] = url
					end
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 30
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
		local count, done = 0, 0
		for _ in colourUrl do
			count += 1
		end
		for part, name in waitingParts do
			if part.Parent and colourUrl[name] then
				addTextures(part, name, colourUrl[name])
				done += 1
			end
		end
		table.clear(waitingParts)
		print(`[Surfaces] texture fallback: {count} colour maps ready, {done} surfaces textured (full PBR needs the one-time command-bar step)`)
	end)
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
		Surfaces.texture(part, name)
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
	if sa and sa:IsA("SurfaceAppearance") and hasMaps(sa) then
		local old = part:FindFirstChildOfClass("SurfaceAppearance")
		if old then
			old:Destroy()
		end
		sa:Clone().Parent = part
	else
		Surfaces.apply(part, name)
	end
end

-- Server start: use what's installed, try to install the rest, report.
-- Never throws and never holds up the server: the level is built straight
-- away with whatever is ready (built-in materials otherwise).
local COMMAND = "require(game.ReplicatedStorage.Shared.Surfaces).install()"

function Surfaces.init()
	Surfaces.refresh() -- variants saved into the place from the command bar
	local count, total, ready = 0, 0, 0
	for name, spec in Surfaces.SPECS do
		count += 1
		if texturesFor(spec.set) then
			total += 1
		end
		if available[name] then
			ready += 1
		end
	end
	if total == 0 then
		print(`[Surfaces] 0 of {count} PBR sets uploaded: built-in materials until then (TODO.md, "Uploads")`)
		return
	end
	if ready >= total then
		print(`[Surfaces] {ready} of {count} PBR sets active`)
		return
	end
	Surfaces.prepareTextures() -- colour maps on the big surfaces meanwhile
	task.spawn(function()
		local ok, made, blocked = pcall(Surfaces.install)
		if not ok then
			warn(`[Surfaces] install failed ({made}); using built-in materials`)
		elseif (blocked :: number) > 0 and ready == 0 then
			warn(`[Surfaces] {total} PBR sets are uploaded but not installed in this place yet (using flat texture fallback). ONE TIME for full PBR: stop the game, paste this in View > Command Bar, press Enter, wait for "[Surfaces] DONE", then File > Save:  {COMMAND}`)
		else
			print(`[Surfaces] {made} of {count} PBR sets active`)
		end
	end)
end

return Surfaces
