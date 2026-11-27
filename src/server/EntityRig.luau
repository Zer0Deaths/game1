--!strict
-- EntityRig: the bodies of SHIFT's entities, as proper R15-style rigs
-- (HumanoidRootPart + 15 named parts joined by Motor6Ds, with an
-- AnimationController and Animator), so animations made in Studio's
-- Animation Editor play on them as they are.
--
--   The Tenant:  very tall and thin, near-black, with a bone-white face
--                (it catches a faint light: Tenant.luau hangs it on the
--                FaceLight attachment). Arms that hang past its knees, a
--                small head pushed forward on a hunched spine.
--   Lampjaw:     a thin black thing that drops out of a light fitting:
--                a long neck ending in a hinged jaw full of pale teeth.
--   The Foreman: broad and square in a work jacket, an old hard hat over a
--                head-shaped hole of pure black, keys on its belt.
--
-- THE BLENDER TENANT (blender/scripts/tenant.py): once its model is
-- uploaded (AssetIds.models.tenant) and loaded, the Tenant is built from
-- it instead: 15 MeshParts joined at the joints the Blender script wrote
-- into the manifest, so the skeleton animated here is the one modelled
-- there. Head hung low, shoulders hunched over it, arms past the knees,
-- elbows that bend the wrong way, up on its toes. The built rig below
-- stays as the fallback until then. The Foreman works the same way
-- (blender/scripts/foreman.py, AssetIds.models.foreman).
--
-- SWAPPING IN A REAL MODEL (Cube or Tripo mesh, see docs/ENTITY_GUIDE.md):
-- put a rigged model in ServerStorage > SHIFT_Models named "Tenant" or
-- "Lampjaw". It needs a HumanoidRootPart, Motor6D joints and an
-- AnimationController (or Humanoid) with an Animator. It's used instead
-- of the built body automatically.
--
-- Animation is done on each player's device (Entities.client): your
-- Animation Editor IDs from Config.ANIMATIONS if set, otherwise a
-- procedural walk, run, idle and attack.
--
-- In Studio's command bar you can drop a built rig into Workspace to
-- animate it in the Animation Editor:
--   require(game.ServerScriptService.Server.EntityRig).spawnForEditing("Tenant")

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Surfaces = require(Shared:WaitForChild("Surfaces"))
local Manifest = require(Shared:WaitForChild("MeshManifest")) :: any
local Meshes = require(script.Parent:WaitForChild("Meshes"))

local EntityRig = {}

local BLACK = Color3.fromRGB(14, 13, 13)
local TEETH = Color3.fromRGB(196, 188, 164)

local function part(m: Model, name: string, size: Vector3, cf: CFrame, ball: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = BLACK
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = true
	if ball then
		p.Shape = Enum.PartType.Ball
	end
	Surfaces.apply(p, "SHIFT_TenantSkin")
	-- Near-black either way: the uploaded skin is already dark, so it is only lightly tinted.
	p.Color = if Surfaces.has("SHIFT_TenantSkin") then Color3.fromRGB(150, 150, 150) else BLACK
	p.Parent = m
	return p
end

-- Joint between two parts at a world point, from their rest pose.
local function motor(name: string, p0: BasePart, p1: BasePart, at: CFrame)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = p0.CFrame:Inverse() * at
	m.C1 = p1.CFrame:Inverse() * at
	m.Parent = p1
end

-- Decoration stuck to a rig part (fingers, joints): moves with it.
local function stuck(m: Model, to: BasePart, name: string, size: Vector3, cf: CFrame, ball: boolean?)
	local p = part(m, name, size, cf, ball)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
	p.Parent = to
end

local function animator(m: Model)
	local controller = Instance.new("AnimationController")
	controller.Parent = m
	local a = Instance.new("Animator")
	a.Parent = controller
end

local function tenant(height: number): Model
	local m = Instance.new("Model")
	m.Name = "Tenant"
	local h = height / 9.5
	local function v(x: number, y: number, z: number): Vector3
		return Vector3.new(x, y, z) * h
	end
	local hip = 4.5 * h

	local root = part(m, "HumanoidRootPart", v(1.2, 1.2, 0.6), CFrame.new(0, hip, 0))
	root.Anchored = true
	root.Transparency = 1
	root.PivotOffset = CFrame.new(0, -hip, 0) -- the model's pivot is at its feet
	m.PrimaryPart = root

	-- Hunched: the chest leans forward and the head juts out.
	local lower = part(m, "LowerTorso", v(0.95, 0.7, 0.5), CFrame.new(v(0, 4.75, 0)))
	local chestCF = CFrame.new(v(0, 6.05, -0.25)) * CFrame.Angles(math.rad(-18), 0, 0)
	local upper = part(m, "UpperTorso", v(1.15, 2.2, 0.55), chestCF)
	local headCF = CFrame.new(v(0, 7.75, -1.0)) * CFrame.Angles(math.rad(-28), 0, 0)
	local head = part(m, "Head", v(0.75, 1.15, 0.85), headCF, false)
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Sphere
	headMesh.Parent = head
	stuck(m, upper, "Neck", v(0.28, 0.9, 0.28), CFrame.new(v(0, 7.25, -0.7)) * CFrame.Angles(math.rad(-40), 0, 0))
	-- The bone-white face on the front of the head, and the point just in
	-- front of it where the faint light it catches hangs.
	local faceCF = headCF * CFrame.new(v(0, -0.05, -0.34))
	local face = part(m, "Face", v(0.5, 0.74, 0.22), faceCF)
	face.MaterialVariant = ""
	face.Material = Enum.Material.SmoothPlastic
	face.Color = Color3.fromRGB(226, 221, 208)
	local faceMesh = Instance.new("SpecialMesh")
	faceMesh.MeshType = Enum.MeshType.Sphere
	faceMesh.Parent = face
	local faceWeld = Instance.new("WeldConstraint")
	faceWeld.Part0, faceWeld.Part1 = head, face
	faceWeld.Parent = face
	for _, ex in { -1, 1 } do
		stuck(m, face, "Pit", v(0.12, 0.09, 0.06), faceCF * CFrame.new(v(ex * 0.11, 0.1, -0.09)), true)
	end
	stuck(m, face, "Mouth", v(0.07, 0.24, 0.05), faceCF * CFrame.new(v(0, -0.17, -0.09)))
	local glow = Instance.new("Attachment")
	glow.Name = "FaceLight"
	glow.Position = v(0, 0, -0.9)
	glow.Parent = face

	motor("Root", root, lower, CFrame.new(v(0, 4.6, 0)))
	motor("Waist", lower, upper, CFrame.new(v(0, 5.05, 0)))
	motor("Neck", upper, head, CFrame.new(v(0, 7.2, -0.7)))

	for _, sideName in { "Left", "Right" } do
		local s = if sideName == "Left" then -1 else 1
		-- Arms: long and thin, hanging to just below the knee.
		local shoulder = v(s * 0.78, 6.85, -0.55)
		local elbow = v(s * 0.92, 4.75, -0.65)
		local wrist = v(s * 0.88, 2.55, -0.7)
		local ua = part(m, `{sideName}UpperArm`, v(0.3, 2.15, 0.3), CFrame.new((shoulder + elbow) / 2))
		local la = part(m, `{sideName}LowerArm`, v(0.26, 2.25, 0.26), CFrame.new((elbow + wrist) / 2))
		local hand = part(m, `{sideName}Hand`, v(0.28, 0.5, 0.14), CFrame.new(wrist - v(0, 0.25, 0)))
		for f = -1, 1 do
			stuck(m, hand, "Finger", v(0.07, 0.95, 0.07), CFrame.new(wrist + v(s * 0.02 + f * 0.08, -0.95 + math.abs(f) * 0.1, 0)) * CFrame.Angles(0, 0, s * f * 0.12))
		end
		stuck(m, ua, "Elbow", v(0.32, 0.32, 0.32), CFrame.new(elbow), true)
		motor(`{sideName}Shoulder`, upper, ua, CFrame.new(shoulder))
		motor(`{sideName}Elbow`, ua, la, CFrame.new(elbow))
		motor(`{sideName}Wrist`, la, hand, CFrame.new(wrist))

		-- Legs: long shins, slightly bent knees.
		local hipJ = v(s * 0.32, 4.45, 0)
		local knee = v(s * 0.36, 2.3, -0.15)
		local ankle = v(s * 0.34, 0.3, 0)
		local ul = part(m, `{sideName}UpperLeg`, v(0.36, 2.2, 0.36), CFrame.new((hipJ + knee) / 2))
		local ll = part(m, `{sideName}LowerLeg`, v(0.3, 2.05, 0.3), CFrame.new((knee + ankle) / 2))
		local foot = part(m, `{sideName}Foot`, v(0.32, 0.22, 0.95), CFrame.new(ankle + v(0, -0.18, -0.25)))
		stuck(m, ul, "Knee", v(0.38, 0.38, 0.38), CFrame.new(knee), true)
		motor(`{sideName}Hip`, lower, ul, CFrame.new(hipJ))
		motor(`{sideName}Knee`, ul, ll, CFrame.new(knee))
		motor(`{sideName}Ankle`, ll, foot, CFrame.new(ankle))
	end
	animator(m)
	return m
end

local function lampjaw(): Model
	local m = Instance.new("Model")
	m.Name = "Lampjaw"
	local root = part(m, "HumanoidRootPart", Vector3.new(0.6, 0.3, 0.6), CFrame.new(0, 0, 0))
	root.Anchored = true
	root.Transparency = 1
	m.PrimaryPart = root
	-- A thin neck hanging from the fitting, then a long hinged jaw.
	local neck = part(m, "Neck", Vector3.new(0.35, 3.2, 0.35), CFrame.new(0, -1.6, 0))
	local skull = part(m, "UpperJaw", Vector3.new(0.9, 0.35, 1.9), CFrame.new(0, -3.3, -0.55))
	local jaw = part(m, "LowerJaw", Vector3.new(0.8, 0.25, 1.8), CFrame.new(0, -3.62, -0.5))
	for i = 0, 5 do
		local z = -1.3 + i * 0.3
		local t1 = part(m, "Tooth", Vector3.new(0.08, 0.28, 0.08), CFrame.new(0.32 * (if i % 2 == 0 then 1 else -1), -3.55, z))
		t1.MaterialVariant = ""
		t1.Material = Enum.Material.Slate
		t1.Color = TEETH
		local w1 = Instance.new("WeldConstraint")
		w1.Part0, w1.Part1 = skull, t1
		w1.Parent = t1
		local t2 = part(m, "Tooth", Vector3.new(0.07, 0.22, 0.07), CFrame.new(-0.3 * (if i % 2 == 0 then 1 else -1), -3.42, z + 0.1))
		t2.MaterialVariant = ""
		t2.Material = Enum.Material.Slate
		t2.Color = TEETH
		local w2 = Instance.new("WeldConstraint")
		w2.Part0, w2.Part1 = jaw, t2
		w2.Parent = t2
	end
	motor("Drop", root, neck, CFrame.new(0, 0, 0))
	motor("Skull", neck, skull, CFrame.new(0, -3.15, 0))
	motor("Jaw", skull, jaw, CFrame.new(0, -3.45, 0.35))
	animator(m)
	return m
end

-- A plain part for the Foreman's built body (it isn't near-black skin).
local function plain(m: Model, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = true
	p.Parent = m
	return p
end

local function weldTo(to: BasePart, p: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
end

-- The Foreman's built body, until its Blender model is uploaded: a broad,
-- square figure in a work jacket, an old hard hat over a head-shaped hole
-- of pure black, keys on its belt. Same joints as foreman.py.
local function foreman(height: number): Model
	local m = Instance.new("Model")
	m.Name = "Foreman"
	local k = height / 8.6
	local function v(x: number, y: number, z: number): Vector3
		return Vector3.new(x, y, z) * k
	end
	local JACKET = Color3.fromRGB(56, 51, 44)
	local TROUSERS = Color3.fromRGB(44, 42, 39)
	local FAB = Enum.Material.Fabric

	local root = plain(m, "HumanoidRootPart", v(1.2, 1.2, 0.6), CFrame.new(v(0, 4.0, 0)), TROUSERS, Enum.Material.SmoothPlastic)
	root.Anchored = true
	root.Transparency = 1
	root.PivotOffset = CFrame.new(0, -4.0 * k, 0) -- the model's pivot is at its feet
	m.PrimaryPart = root

	local lower = plain(m, "LowerTorso", v(2.1, 1.2, 1.25), CFrame.new(v(0, 4.1, 0)), TROUSERS, FAB)
	local upper = plain(m, "UpperTorso", v(3.1, 2.8, 1.45), CFrame.new(v(0, 6.0, 0)), JACKET, FAB)
	for s = -1, 1, 2 do
		local sh = plain(m, "Shoulder", v(1.4, 1.0, 1.25), CFrame.new(v(s * 1.62, 6.95, -0.08)), JACKET, FAB)
		weldTo(upper, sh)
	end
	local band = plain(m, "ChestBand", v(3.15, 0.28, 1.5), CFrame.new(v(0, 5.76, 0)), Color3.fromRGB(176, 176, 166), Enum.Material.Foil)
	weldTo(upper, band)
	local collar = plain(m, "Collar", v(1.35, 0.45, 1.25), CFrame.new(v(0, 7.45, 0.02)), JACKET, FAB)
	weldTo(upper, collar)
	local keys = plain(m, "Keys", v(0.12, 0.7, 0.45), CFrame.new(v(1.2, 3.8, -0.12)), Color3.fromRGB(150, 140, 112), Enum.Material.Metal)
	weldTo(lower, keys)

	-- The hat, and nothing under it.
	local head = plain(m, "Head", v(1.35, 0.95, 1.5), CFrame.new(v(0, 8.2, 0.02)), Color3.fromRGB(178, 162, 112), Enum.Material.SmoothPlastic)
	local dome = Instance.new("SpecialMesh")
	dome.MeshType = Enum.MeshType.Sphere
	dome.Parent = head
	local brim = plain(m, "Brim", v(0.1, 1.75, 2.05), CFrame.new(v(0, 8.1, -0.12)) * CFrame.Angles(0, 0, math.pi / 2), head.Color, Enum.Material.SmoothPlastic)
	brim.Shape = Enum.PartType.Cylinder
	weldTo(head, brim)
	local void = plain(m, "FaceVoid", v(1.0, 1.0, 1.0), CFrame.new(v(0, 7.8, -0.04)), Color3.new(0, 0, 0), Enum.Material.Neon)
	void.Shape = Enum.PartType.Ball
	weldTo(head, void)

	motor("Root", root, lower, CFrame.new(v(0, 4.0, 0)))
	motor("Waist", lower, upper, CFrame.new(v(0, 4.6, 0)))
	motor("Neck", upper, head, CFrame.new(v(0, 7.4, 0)))
	for _, side in { "Left", "Right" } do
		local s = if side == "Left" then -1 else 1
		local shoulder, elbow, wrist = v(s * 1.86, 6.85, -0.06), v(s * 2.06, 4.75, 0.02), v(s * 2.1, 2.85, -0.1)
		local ua = plain(m, `{side}UpperArm`, v(1.0, 2.3, 1.0), CFrame.new((shoulder + elbow) / 2), JACKET, FAB)
		local la = plain(m, `{side}LowerArm`, v(0.82, 2.0, 0.82), CFrame.new((elbow + wrist) / 2), JACKET, FAB)
		local hand = plain(m, `{side}Hand`, v(0.5, 1.15, 0.9), CFrame.new(wrist - v(0, 0.55, 0)), Color3.fromRGB(82, 70, 52), FAB)
		motor(`{side}Shoulder`, upper, ua, CFrame.new(shoulder))
		motor(`{side}Elbow`, ua, la, CFrame.new(elbow))
		motor(`{side}Wrist`, la, hand, CFrame.new(wrist))
		local hip, knee, ankle = v(s * 0.56, 3.85, 0), v(s * 0.6, 2.25, -0.05), v(s * 0.6, 0.72, 0.05)
		local ul = plain(m, `{side}UpperLeg`, v(1.1, 1.75, 1.1), CFrame.new((hip + knee) / 2), TROUSERS, FAB)
		local ll = plain(m, `{side}LowerLeg`, v(0.88, 1.55, 0.88), CFrame.new((knee + ankle) / 2), TROUSERS, FAB)
		local foot = plain(m, `{side}Foot`, v(0.9, 0.95, 1.7), CFrame.new(ankle + v(0, -0.25, -0.3)), Color3.fromRGB(30, 28, 26), Enum.Material.Rubber)
		motor(`{side}Hip`, lower, ul, CFrame.new(hip))
		motor(`{side}Knee`, ul, ll, CFrame.new(knee))
		motor(`{side}Ankle`, ll, foot, CFrame.new(ankle))
	end
	animator(m)
	return m
end

-- R15 joints: name -> (Part0, Part1). Positions come from the manifest.
local R15 = {
	Root = { "HumanoidRootPart", "LowerTorso" },
	Waist = { "LowerTorso", "UpperTorso" },
	Neck = { "UpperTorso", "Head" },
}
for _, side in { "Left", "Right" } do
	R15[`{side}Shoulder`] = { "UpperTorso", `{side}UpperArm` }
	R15[`{side}Elbow`] = { `{side}UpperArm`, `{side}LowerArm` }
	R15[`{side}Wrist`] = { `{side}LowerArm`, `{side}Hand` }
	R15[`{side}Hip`] = { "LowerTorso", `{side}UpperLeg` }
	R15[`{side}Knee`] = { `{side}UpperLeg`, `{side}LowerLeg` }
	R15[`{side}Ankle`] = { `{side}LowerLeg`, `{side}Foot` }
end

-- Entities modelled in Blender as R15 parts (blender/scripts/<mesh>.py):
-- the mesh name and the height each was modelled at.
local MESH_RIGS: { [string]: { mesh: string, height: number } } = {
	Tenant = { mesh = "tenant", height = 9.5 },
	Foreman = { mesh = "foreman", height = 8.6 },
}

-- A Blender entity, or nil while its model isn't uploaded or loaded.
-- Scaled from the height it was modelled at. Its R15 parts are joined at
-- the joints the script wrote into the manifest; any extra pieces (a hat
-- void, keys, reflective bands) are welded to the part they say they ride
-- on (their "attach").
local function rigFromMesh(name: string, height: number): Model?
	local info = MESH_RIGS[name]
	local spec = info and Manifest[info.mesh]
	if not (info and spec and spec.joints and Meshes.ready(info.mesh)) then
		return nil
	end
	local k = height / info.height
	local meshes = Meshes.build(info.mesh, CFrame.identity, { scale = k })
	if not meshes then
		return nil
	end
	local m = Instance.new("Model")
	m.Name = name
	local parts: { [string]: BasePart } = {}
	for _, mp in meshes:GetChildren() do
		if mp:IsA("BasePart") then
			mp.Anchored = false
			mp.Massless = true
			mp.CanCollide = false
			mp.CanQuery = false
			mp.CanTouch = false
			mp.CastShadow = true
			mp.Parent = m
			parts[mp.Name] = mp
		end
	end
	meshes:Destroy()
	local hip = spec.joints.Root.Y * k
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(1.2, 1.2, 0.6) * k
	root.CFrame = CFrame.new(0, hip, 0)
	root.Anchored = true
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.PivotOffset = CFrame.new(0, -hip, 0) -- the model's pivot is at its feet
	root.Parent = m
	m.PrimaryPart = root
	parts.HumanoidRootPart = root
	for joint, pair in R15 do
		local p0, p1 = parts[pair[1]], parts[pair[2]]
		local at = spec.joints[joint]
		if not (p0 and p1 and at) then
			warn(`[EntityRig] Blender {name} is missing {joint}: using the built rig`)
			m:Destroy()
			return nil
		end
		motor(joint, p0, p1, CFrame.new(at * k))
	end
	for _, piece in spec.parts do
		local p, to = parts[piece.name], parts[piece.attach or ""]
		if p and to and p ~= to then
			local w = Instance.new("Weld")
			w.Part0 = to
			w.Part1 = p
			w.C0 = to.CFrame:Inverse() * p.CFrame
			w.Parent = p
		end
	end
	-- A point the script marked in front of the face ("FaceLight" in the
	-- joints, not a joint): the entity's code hangs a light there.
	local glowAt = spec.joints.FaceLight
	local face = parts.Face
	if glowAt and face then
		local a = Instance.new("Attachment")
		a.Name = "FaceLight"
		a.Position = face.CFrame:PointToObjectSpace(glowAt * k)
		a.Parent = face
	end
	animator(m)
	return m
end

local BUILDERS: { [string]: (number) -> Model } = {
	Tenant = tenant,
	Foreman = foreman,
	Lampjaw = function()
		return lampjaw()
	end,
}

-- A fresh body for an entity: Jason's own model if there is one in
-- ServerStorage.SHIFT_Models, otherwise the built rig.
function EntityRig.build(name: string, height: number?): Model
	local custom = ServerStorage:FindFirstChild("SHIFT_Models")
	local own = custom and custom:FindFirstChild(name)
	local m: Model
	if own and own:IsA("Model") and own:FindFirstChild("HumanoidRootPart") then
		m = own:Clone()
		local root = m:FindFirstChild("HumanoidRootPart") :: BasePart
		root.Anchored = true
		m.PrimaryPart = root
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				if d ~= root then
					d.Anchored = false
					d.Massless = true
				end
			end
		end
		print(`[EntityRig] using your {name} model from ServerStorage.SHIFT_Models`)
	else
		local fromMesh = rigFromMesh(name, height or 9.5)
		if fromMesh then
			m = fromMesh
			print(`[EntityRig] {name}: the Blender model`)
		else
			m = BUILDERS[name](height or 9.5)
		end
	end
	m.Name = name
	pcall(function()
		m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	m:SetAttribute("Entity", name)
	CollectionService:AddTag(m, "SHIFT_Entity")
	return m
end

-- Studio helper: a posable copy in Workspace for the Animation Editor.
function EntityRig.spawnForEditing(name: string): Model
	local h = if MESH_RIGS[name] then MESH_RIGS[name].height else 9.5
	local m = rigFromMesh(name, h) or BUILDERS[name](h)
	m.Name = `{name}Rig`
	m:PivotTo(CFrame.new(0, 20, 0))
	m.Parent = workspace
	return m
end

return EntityRig
