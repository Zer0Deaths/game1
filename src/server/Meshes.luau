--!strict
-- Meshes: swaps SHIFT's Blender models in for the primitive parts.
--
-- blender/build_all.py writes Shared.MeshManifest (each model's meshes:
-- size, centre, look) and tools/upload_assets.py uploads each FBX as a
-- Model asset (AssetIds.models). On server start every uploaded model is
-- loaded (InsertService) in the background; each builder then calls
-- Meshes.dress with the primitive parts a mesh replaces. Until a model is
-- uploaded and loaded the primitives simply stay, so nothing ever breaks.
--
-- Placement never trusts how Roblox positions an imported model: every
-- MeshPart is sized and placed from the manifest, in the same frame the
-- Blender script modelled it in (the frame the Luau code builds in).

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AssetIds = require(Shared:WaitForChild("AssetIds"))
local Manifest = require(Shared:WaitForChild("MeshManifest")) :: any
local Surfaces = require(Shared:WaitForChild("Surfaces"))

local Meshes = {}

export type Opts = {
	skip: { string }?, -- mesh names not to place
	only: { string }?, -- place just these
	scale: number?, -- uniform scale (rigs built at another height)
	solid: boolean?, -- meshes collide (otherwise the primitives stay as invisible colliders)
	copy: { [string]: BasePart }?, -- mesh name -> primitive whose colour and material it keeps (level themes)
	restyle: { [string]: { colour: Color3?, material: Enum.Material? } }?, -- per-mesh overrides
	onBuilt: ((Model) -> ())?, -- after the meshes are placed
}

type Template = { mesh: MeshPart, rot: CFrame, perm: { number } }

local templates: { [string]: { [string]: Template } } = {}
local state: { [string]: string } = {} -- "loading" | "ready" | "failed"
local waiting: { [string]: { () -> () } } = {}
local pending = 0
local loaded, failedList = 0, {}

local function idOf(name: string): number?
	local ids = (AssetIds :: any).models
	local id = ids and ids[name]
	return if typeof(id) == "string" then tonumber(id) else nil
end

-- Is there an uploaded mesh for this model?
function Meshes.has(name: string): boolean
	return idOf(name) ~= nil and Manifest[name] ~= nil
end

function Meshes.ready(name: string): boolean
	return state[name] == "ready"
end

-- The model's overall size (studs), from the manifest.
function Meshes.size(name: string): Vector3?
	local spec = Manifest[name]
	return spec and spec.size
end

-- How the uploaded mesh's own axes line up with the manifest's. Normally
-- identical; if the importer turned it, the proportions tell us which way.
local PERMS: { { perm: { number }, rot: CFrame } } = {
	{ perm = { 1, 2, 3 }, rot = CFrame.identity },
	{ perm = { 1, 3, 2 }, rot = CFrame.Angles(math.rad(90), 0, 0) },
	{ perm = { 3, 2, 1 }, rot = CFrame.Angles(0, math.rad(90), 0) },
	{ perm = { 2, 1, 3 }, rot = CFrame.Angles(0, 0, math.rad(90)) },
}

local function axes(v: Vector3): { number }
	return { v.X, v.Y, v.Z }
end

local function fit(meshSize: Vector3, want: Vector3): (CFrame, { number }, number)
	local m, w = axes(meshSize), axes(want)
	local best, bestErr, idErr = PERMS[1], math.huge, math.huge
	for _, p in PERMS do
		-- log ratios should all be equal (uniform scale) when the axes match
		local logs = {}
		for i = 1, 3 do
			logs[i] = math.log(math.max(m[i], 1e-3) / math.max(w[p.perm[i]], 1e-3))
		end
		local mean = (logs[1] + logs[2] + logs[3]) / 3
		local err = math.abs(logs[1] - mean) + math.abs(logs[2] - mean) + math.abs(logs[3] - mean)
		if p == PERMS[1] then
			idErr = err
		end
		if err < bestErr then
			best, bestErr = p, err
		end
	end
	-- Prefer as-is unless another way round is clearly better.
	if idErr - bestErr < 0.2 then
		return CFrame.identity, PERMS[1].perm, idErr
	end
	return best.rot, best.perm, bestErr
end

local function finishOne(name: string, ok: boolean, why: string?)
	state[name] = if ok then "ready" else "failed"
	if ok then
		loaded += 1
	else
		table.insert(failedList, `{name} ({why})`)
	end
	local list = waiting[name]
	waiting[name] = nil
	if ok and list then
		for _, fn in list do
			task.spawn(fn)
		end
	end
	pending -= 1
	if pending == 0 then
		print(`[Meshes] {loaded} models loaded` .. (if #failedList > 0 then `, {#failedList} failed: {table.concat(failedList, ", ")}` else ""))
	end
end

local function load(name: string)
	if state[name] then
		return
	end
	local id, spec = idOf(name), Manifest[name]
	if not id or not spec then
		state[name] = "failed"
		return
	end
	state[name] = "loading"
	pending += 1
	task.spawn(function()
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if not ok or not asset then
			finishOne(name, false, tostring(asset))
			return
		end
		local found: { MeshPart } = {}
		for _, d in asset:GetDescendants() do
			if d:IsA("MeshPart") then
				table.insert(found, d)
			end
		end
		local map: { [string]: Template } = {}
		local used: { [MeshPart]: boolean } = {}
		local turned = {}
		if #found == 1 and #spec.parts > 1 then
			-- The importer merged everything into one mesh: place it whole
			-- (Meshes.build), in the look of its biggest piece.
			local mp = found[1]
			local meshSize = mp.Size
			pcall(function()
				meshSize = (mp :: any).MeshSize
			end)
			local rot, perm = fit(meshSize, spec.size)
			local template = mp:Clone()
			for _, child in template:GetChildren() do
				if not child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
			map.__whole = { mesh = template, rot = rot, perm = perm }
			warn(`[Meshes] {name} came in as one merged mesh: placed whole, in one look (tell Claude)`)
			found = {}
		end
		for _, p in spec.parts do
			-- By name first ("Door_Frame"), then the unused mesh closest in shape.
			local pick: MeshPart? = nil
			for _, mp in found do
				if not used[mp] and (mp.Name == p.name or string.find(mp.Name, p.name, 1, true) == 1) then
					pick = mp
					break
				end
			end
			if not pick then
				local bestErr = math.huge
				for _, mp in found do
					if not used[mp] then
						local _, _, err = fit(mp.Size, p.size)
						if err < bestErr then
							pick, bestErr = mp, err
						end
					end
				end
			end
			if pick then
				used[pick] = true
				local meshSize = pick.Size
				pcall(function()
					meshSize = (pick :: any).MeshSize
				end)
				local rot, perm = fit(meshSize, p.size)
				if rot ~= CFrame.identity then
					table.insert(turned, p.name)
				end
				local template = pick:Clone()
				for _, child in template:GetChildren() do
					if not child:IsA("SurfaceAppearance") then
						child:Destroy()
					end
				end
				map[p.name] = { mesh = template, rot = rot, perm = perm }
			end
		end
		asset:Destroy()
		local count = 0
		for _ in map do
			count += 1
		end
		if count == 0 then
			finishOne(name, false, `no meshes in asset {id}`)
			return
		end
		templates[name] = map
		if count < #spec.parts and not map.__whole then
			warn(`[Meshes] {name}: only {count} of {#spec.parts} meshes found in its upload`)
		end
		if #turned > 0 then
			warn(`[Meshes] {name}: {table.concat(turned, ", ")} came in turned; corrected (tell Claude if it looks upside down)`)
		end
		finishOne(name, true)
	end)
end

-- Server start: load every uploaded model in the background.
function Meshes.preload()
	local ids = (AssetIds :: any).models
	if not ids then
		return
	end
	for name in ids do
		load(name)
	end
end

local function paint(mp: MeshPart, p: any)
	mp.Color = p.colour
	local ok, material = pcall(function()
		return (Enum.Material :: any)[p.material]
	end)
	mp.Material = if ok and material then material else Enum.Material.Plastic
	mp.MaterialVariant = ""
	if p.surface ~= "" and Surfaces.has(p.surface) then
		Surfaces.applyMesh(mp, p.surface)
	end
	mp.Transparency = p.transparency
	mp.CastShadow = p.shadow
end

-- Clones of a model's meshes placed in `frame` (the frame its Blender
-- script modelled it in). nil until the model has loaded.
function Meshes.build(name: string, frame: CFrame, opts: Opts?): Model?
	local map = templates[name]
	local spec = Manifest[name]
	if not map or not spec then
		return nil
	end
	local o: Opts = opts or {}
	local k = o.scale or 1
	local model = Instance.new("Model")
	model.Name = name
	local whole = map.__whole
	if whole then
		-- Merged on import: no picking pieces out of it, so a caller that
		-- wanted only some of them keeps its plain parts instead.
		if o.only or o.skip then
			model:Destroy()
			return nil
		end
		local biggest = spec.parts[1]
		for _, p in spec.parts do
			if p.size.X * p.size.Y * p.size.Z > biggest.size.X * biggest.size.Y * biggest.size.Z then
				biggest = p
			end
		end
		local want = axes(spec.size * k)
		local mp = whole.mesh:Clone()
		mp.Name = name
		mp.Size = Vector3.new(want[whole.perm[1]], want[whole.perm[2]], want[whole.perm[3]])
		mp.CFrame = frame * CFrame.new((spec.origin + Vector3.new(0, spec.size.Y / 2, 0)) * k) * whole.rot
		mp.Anchored = true
		mp.CanCollide = o.solid == true
		mp.CanQuery = o.solid == true
		mp.CanTouch = false
		mp:SetAttribute("Visual", true)
		paint(mp, biggest)
		mp.Parent = model
		return model
	end
	for _, p in spec.parts do
		if (o.skip and table.find(o.skip, p.name)) or (o.only and not table.find(o.only, p.name)) then
			continue
		end
		local t = map[p.name]
		if not t then
			continue
		end
		local want = axes(p.size * k)
		local mp = t.mesh:Clone()
		mp.Name = p.name
		mp.Size = Vector3.new(want[t.perm[1]], want[t.perm[2]], want[t.perm[3]])
		mp.CFrame = frame * CFrame.new((spec.origin + p.centre) * k) * t.rot
		mp.Anchored = true
		mp.CanCollide = o.solid == true
		mp.CanQuery = o.solid == true
		mp.CanTouch = false
		mp:SetAttribute("Visual", true)
		paint(mp, p)
		local from = o.copy and o.copy[p.name]
		if from then
			local sa = mp:FindFirstChildOfClass("SurfaceAppearance")
			if sa then
				sa:Destroy()
			end
			mp.Color = from.Color
			mp.Material = from.Material
			mp.MaterialVariant = from.MaterialVariant
		end
		local style = o.restyle and o.restyle[p.name]
		if style then
			if style.material then
				local sa = mp:FindFirstChildOfClass("SurfaceAppearance")
				if sa then
					sa:Destroy()
				end
				mp.Material = style.material
				mp.MaterialVariant = ""
			end
			if style.colour then
				mp.Color = style.colour
			end
		end
		mp.Parent = model
	end
	return model
end

-- A primitive the mesh replaces: solid ones stay as invisible colliders,
-- ones carrying text, lights or tags stay invisible, the rest go.
local function retire(prim: BasePart, solidMesh: boolean)
	local keep = prim.CanCollide and not solidMesh
	for _, child in prim:GetChildren() do
		if child:IsA("SurfaceGui") or child:IsA("Light") or child:IsA("Attachment") or child:IsA("ProximityPrompt") then
			keep = true
		end
	end
	if #prim:GetTags() > 0 then
		keep = true
	end
	if keep then
		prim.Transparency = 1
		prim.CastShadow = false
		for _, child in prim:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				child:Destroy()
			end
		end
	else
		prim:Destroy()
	end
end

-- Swap `primitives` for model `name` placed at `frame`, now if it has
-- loaded or as soon as it does. Returns false (and changes nothing) when
-- there's no uploaded mesh for it.
function Meshes.dress(name: string, frame: CFrame, parent: Instance, primitives: { BasePart }, opts: Opts?): boolean
	if not Meshes.has(name) then
		return false
	end
	local function apply()
		-- Gone (a Shift rebuilt it) before the mesh arrived: Destroy clears
		-- the Parent of everything under it. During a build the parent may
		-- not be in the world yet, which is fine.
		if parent.Parent == nil then
			return
		end
		for _, prim in primitives do
			if not prim.Parent then
				return
			end
		end
		local model = Meshes.build(name, frame, opts)
		if not model then
			return
		end
		local solid = opts ~= nil and opts.solid == true
		for _, prim in primitives do
			retire(prim, solid)
		end
		model.Parent = parent
		if opts and opts.onBuilt then
			opts.onBuilt(model)
		end
	end
	if state[name] == "ready" then
		apply()
	elseif state[name] ~= "failed" then
		load(name)
		local list = waiting[name] or {}
		waiting[name] = list
		table.insert(list, apply)
	end
	return true
end

-- Meshes welded to a moving part (loot in hand, a rig limb). `frame` is
-- where the model's frame sits relative to the part. The part goes
-- invisible; the meshes go in a Model named "Visual" under it.
function Meshes.attach(name: string, part: BasePart, frame: CFrame, opts: Opts?): boolean
	if not Meshes.has(name) then
		return false
	end
	local function apply()
		if not part.Parent then
			return
		end
		local model = Meshes.build(name, part.CFrame * frame, opts)
		if not model then
			return
		end
		model.Name = "Visual"
		for _, mp in model:GetChildren() do
			if mp:IsA("BasePart") then
				mp.Anchored = false
				mp.Massless = true
				-- A Weld with a fixed offset (not a WeldConstraint), so copies
				-- (the back-load) and moves while out of the world stay right.
				local weld = Instance.new("Weld")
				weld.Part0 = part
				weld.Part1 = mp
				weld.C0 = part.CFrame:ToObjectSpace(mp.CFrame)
				weld.Parent = mp
			end
		end
		part.Transparency = 1
		model.Parent = part
		if opts and opts.onBuilt then
			opts.onBuilt(model)
		end
	end
	if state[name] == "ready" then
		apply()
	elseif state[name] ~= "failed" then
		load(name)
		local list = waiting[name] or {}
		waiting[name] = list
		table.insert(list, apply)
	end
	return true
end

return Meshes
