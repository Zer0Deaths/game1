--!strict
-- Materials: SHIFT's own surface textures (wallpaper, carpet, ceiling
-- tile, concrete) as MaterialVariants, so walls and floors stop looking
-- like stock Roblox plastic.
--
-- The texture images live in assets/textures/ (original, generated for
-- SHIFT, free to use). Roblox can only use uploaded images, so until
-- the IDs are pasted into Config.TEXTURES the level uses built-in
-- materials. See TODO.md for the upload steps.
--
-- If a MaterialVariant with one of these names already exists in
-- MaterialService (for example one made by hand in Studio's Material
-- Manager), it is used as it is.

local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Materials = {}

local SPECS: { [string]: { key: string, base: Enum.Material, studsPerTile: number } } = {
	SHIFT_Wallpaper = { key = "wallpaper", base = Enum.Material.Plaster, studsPerTile = 8 },
	SHIFT_Carpet = { key = "carpet", base = Enum.Material.Carpet, studsPerTile = 10 },
	SHIFT_CeilingTile = { key = "ceiling", base = Enum.Material.Plaster, studsPerTile = 10 },
	SHIFT_Concrete = { key = "concrete", base = Enum.Material.Concrete, studsPerTile = 14 },
}

local function asset(id: string?): string
	if not id or id == "" then
		return ""
	end
	if string.find(id, "://", 1, true) then
		return id
	end
	return "rbxassetid://" .. id
end

function Materials.init()
	local made = 0
	for name, spec in SPECS do
		if MaterialService:FindFirstChild(name) then
			made += 1
			continue
		end
		local ids = (Config.TEXTURES :: any)[spec.key]
		if not ids or (ids.colour or "") == "" then
			continue
		end
		local v = Instance.new("MaterialVariant")
		v.Name = name
		v.BaseMaterial = spec.base
		v.StudsPerTile = spec.studsPerTile
		v.ColorMap = asset(ids.colour)
		v.NormalMap = asset(ids.normal)
		v.RoughnessMap = asset(ids.roughness)
		v.Parent = MaterialService
		made += 1
	end
	print(`[Materials] {made} of 4 SHIFT textures active` .. (if made == 0 then " (built-in materials until the textures are uploaded, see TODO.md)" else ""))
end

-- Is this variant available?
function Materials.has(name: string): boolean
	local v = MaterialService:FindFirstChild(name)
	return v ~= nil and v:IsA("MaterialVariant")
end

-- The built-in material a variant sits on.
function Materials.base(name: string): Enum.Material
	local v = MaterialService:FindFirstChild(name)
	if v and v:IsA("MaterialVariant") then
		return v.BaseMaterial
	end
	local spec = SPECS[name]
	return if spec then spec.base else Enum.Material.Plastic
end

return Materials
