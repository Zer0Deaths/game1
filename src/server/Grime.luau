--!strict
-- Grime: the decals that make rooms look lived in (water stains, scuffs,
-- dirt banked in corners, worn carpet paths, peeling wallpaper, rust runs).
-- Images are made by tools/make_decals.py and uploaded with the rest
-- (tools/upload_assets.py fills AssetIds.decals).
--
-- A decal sits on an invisible, non-colliding holder part just off the
-- surface, so it can be any size and anywhere. Until a decal is uploaded
-- nothing is placed (callers keep their simple fallback). Never yields:
-- uploaded images are looked up in the background and filled in.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AssetIds = require(Shared:WaitForChild("AssetIds"))
local Surfaces = require(Shared:WaitForChild("Surfaces"))

local Grime = {}

local images: { [string]: string } = {}
local waiting: { [string]: { Decal } } = {}

local function idOf(key: string): string
	local decals = (AssetIds :: any).decals
	local id = decals and decals[key]
	return if typeof(id) == "string" then id else ""
end

-- Is this decal uploaded?
function Grime.has(key: string): boolean
	return idOf(key) ~= ""
end

local function resolve(key: string)
	if images[key] or waiting[key] then
		return
	end
	waiting[key] = {}
	task.spawn(function()
		local ok, image = pcall(Surfaces.image, idOf(key))
		local url = if ok and image then image else ""
		images[key] = url
		for _, d in waiting[key] do
			if d.Parent then
				d.Texture = url
			end
		end
		waiting[key] = nil
	end)
end

-- Look every uploaded decal up now (server start), so builds find them ready.
function Grime.preload()
	local decals = (AssetIds :: any).decals
	if decals then
		for key in decals do
			if Grime.has(key) then
				resolve(key)
			end
		end
	end
end

-- Put decal `key` on one face of a part. Returns the Decal, or nil if that
-- decal isn't uploaded yet.
function Grime.decal(part: BasePart, face: Enum.NormalId, key: string, transparency: number?, colour: Color3?): Decal?
	if not Grime.has(key) then
		return nil
	end
	local d = Instance.new("Decal")
	d.Name = key
	d.Face = face
	d.Transparency = transparency or 0
	d.Color3 = colour or Color3.new(1, 1, 1)
	d.ZIndex = 1
	if images[key] then
		d.Texture = images[key]
	else
		resolve(key)
		local list = waiting[key]
		if list then
			table.insert(list, d)
		elseif images[key] then
			d.Texture = images[key]
		end
	end
	d.Parent = part
	return d
end

-- An invisible holder part with a decal on it. `cf` is the holder's centre;
-- `size` its size; `face` the face that shows. Returns nil if not uploaded.
-- `make` builds the part (callers pass their own so level offsets apply).
function Grime.patch(
	make: (props: { [string]: any }) -> BasePart,
	key: string,
	cf: CFrame,
	size: Vector3,
	face: Enum.NormalId,
	transparency: number?,
	colour: Color3?
): BasePart?
	if not Grime.has(key) then
		return nil
	end
	local p = make({
		Name = "Grime",
		Size = size,
		CFrame = cf,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
	})
	Grime.decal(p, face, key, transparency, colour)
	return p
end

return Grime
