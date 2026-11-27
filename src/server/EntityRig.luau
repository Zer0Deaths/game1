--!strict
-- EntityRig: the bodies of SHIFT's entities, as proper R15-style rigs
-- (HumanoidRootPart + 15 named parts joined by Motor6Ds, with an
-- AnimationController and Animator), so animations made in Studio's
-- Animation Editor play on them as they are.
--
--   The Tenant:  very tall and thin, near-black, featureless. Arms that
--                hang past its knees, a small blank head pushed forward
--                on a hunched spine.
--   Lampjaw:     a thin black thing that drops out of a light fitting:
--                a long neck ending in a hinged jaw full of pale teeth.
--
-- THE BLENDER TENANT (blender/scripts/tenant.py): once its model is
-- uploaded (AssetIds.models.tenant) and loaded, the Tenant is built from
-- it instead: 15 MeshParts joined at the joints the Blender script wrote
-- into the manifest, so the skeleton animated here is the one modelled
-- there. Head hung low, shoulders hunched over it, arms past the knees,
-- elbows that bend the wrong way, up on its toes. The built rig below
-- stays as the fallback until then.
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

-- The Blender Tenant, or nil while its model isn't uploaded or loaded.
-- Modelled at 9.5 studs (Config.TENANT.height), scaled for other heights.
local function tenantFromMesh(height: number): Model?
	local spec = Manifest.tenant
	if not (spec and spec.joints and Meshes.ready("tenant")) then
		return nil
	end
	local k = height / 9.5
	local meshes = Meshes.build("tenant", CFrame.identity, { scale = k })
	if not meshes then
		return nil
	end
	local m = Instance.new("Model")
	m.Name = "Tenant"
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
	for name, pair in R15 do
		local p0, p1 = parts[pair[1]], parts[pair[2]]
		local at = spec.joints[name]
		if not (p0 and p1 and at) then
			warn(`[EntityRig] Blender Tenant is missing {name}: using the built rig`)
			m:Destroy()
			return nil
		end
		motor(name, p0, p1, CFrame.new(at * k))
	end
	animator(m)
	return m
end

local BUILDERS: { [string]: (number) -> Model } = {
	Tenant = tenant,
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
		local fromMesh = if name == "Tenant" then tenantFromMesh(height or 9.5) else nil
		if fromMesh then
			m = fromMesh
			print("[EntityRig] Tenant: the Blender model")
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
	local m = (if name == "Tenant" then tenantFromMesh(9.5) else nil) or BUILDERS[name](9.5)
	m.Name = `{name}Rig`
	m:PivotTo(CFrame.new(0, 20, 0))
	m.Parent = workspace
	return m
end

return EntityRig
