--!strict
-- MeleeModels: what the four armoury weapons look like (ShopItems ids
-- melee_pipe, melee_crowbar, melee_axe, melee_sledge). Each is built from
-- plain parts in the frame its Blender script models it in (origin at the
-- bottom of the handle, the shaft up +Y, the business end facing -Z), and
-- the Blender mesh of the same name replaces them once it's uploaded.
--   build(id, frame, parent)  one hanging on the armoury board
--   held(id, hand)            one welded into a character's right hand

local Meshes = require(script.Parent:WaitForChild("Meshes"))

local MeleeModels = {}

MeleeModels.GRIP = 0.45 -- studs up the handle where the hand holds it

type Spec = { name: string, size: Vector3, at: CFrame, colour: Color3, material: Enum.Material, cylinder: boolean? }

local STEEL = Color3.fromRGB(120, 120, 116)
local DARK = Color3.fromRGB(52, 52, 50)
local RED = Color3.fromRGB(150, 32, 26)
local TAPE = Color3.fromRGB(30, 30, 28)

-- A cylinder along Y (Roblox cylinders run along X).
local function rod(name: string, length: number, radius: number, y: number, colour: Color3, material: Enum.Material): Spec
	return {
		name = name,
		size = Vector3.new(length, radius * 2, radius * 2),
		at = CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)),
		colour = colour,
		material = material,
		cylinder = true,
	}
end

local SPECS: { [string]: { Spec } } = {
	melee_pipe = {
		rod("Pipe", 2.8, 0.12, 1.4, STEEL, Enum.Material.Metal),
		rod("Grip", 0.8, 0.14, 0.5, TAPE, Enum.Material.Fabric),
		{ name = "Elbow", size = Vector3.new(0.34, 0.34, 0.5), at = CFrame.new(0, 2.78, -0.08), colour = STEEL, material = Enum.Material.Metal },
	},
	melee_crowbar = {
		{ name = "Shaft", size = Vector3.new(0.16, 2.3, 0.16), at = CFrame.new(0, 1.15, 0), colour = RED, material = Enum.Material.Metal },
		{ name = "Hook", size = Vector3.new(0.16, 0.6, 0.16), at = CFrame.new(0, 2.42, -0.2) * CFrame.Angles(math.rad(50), 0, 0), colour = RED, material = Enum.Material.Metal },
		{ name = "Claw", size = Vector3.new(0.2, 0.08, 0.24), at = CFrame.new(0, 2.5, -0.44), colour = DARK, material = Enum.Material.Metal },
		{ name = "Chisel", size = Vector3.new(0.2, 0.2, 0.1), at = CFrame.new(0, 0.04, -0.03) * CFrame.Angles(math.rad(-20), 0, 0), colour = DARK, material = Enum.Material.Metal },
	},
	melee_axe = {
		{ name = "Handle", size = Vector3.new(0.2, 3.1, 0.14), at = CFrame.new(0, 1.55, 0), colour = Color3.fromRGB(150, 112, 70), material = Enum.Material.Wood },
		{ name = "Head", size = Vector3.new(0.18, 0.5, 0.9), at = CFrame.new(0, 2.8, -0.15), colour = RED, material = Enum.Material.Metal },
		{ name = "Edge", size = Vector3.new(0.1, 0.78, 0.14), at = CFrame.new(0, 2.8, -0.65), colour = STEEL, material = Enum.Material.Metal },
		{ name = "Spike", size = Vector3.new(0.12, 0.14, 0.42), at = CFrame.new(0, 2.8, 0.45), colour = RED, material = Enum.Material.Metal },
	},
	melee_sledge = {
		{ name = "Handle", size = Vector3.new(0.17, 3.0, 0.17), at = CFrame.new(0, 1.5, 0), colour = Color3.fromRGB(176, 150, 96), material = Enum.Material.Wood },
		{ name = "Head", size = Vector3.new(0.5, 0.5, 1.2), at = CFrame.new(0, 3.0, 0), colour = DARK, material = Enum.Material.Metal },
		rod("Grip", 0.7, 0.11, 0.42, TAPE, Enum.Material.Rubber),
	},
}

function MeleeModels.has(id: string): boolean
	return SPECS[id] ~= nil
end

local function parts(id: string, frame: CFrame, parent: Instance): { BasePart }
	local list: { BasePart } = {}
	for _, s in SPECS[id] or {} do
		local p = Instance.new("Part")
		p.Name = s.name
		p.Shape = if s.cylinder then Enum.PartType.Cylinder else Enum.PartType.Block
		p.Size = s.size
		p.CFrame = frame * s.at
		p.Color = s.colour
		p.Material = s.material
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		table.insert(list, p)
	end
	return list
end

-- A weapon standing in `frame` (on the armoury board).
function MeleeModels.build(id: string, frame: CFrame, parent: Instance): Model?
	if not SPECS[id] then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = id
	model.Parent = parent
	local prims = parts(id, frame, model)
	Meshes.dress(id, frame, model, prims)
	return model
end

-- A weapon in a character's right hand. Returns the "Melee" model (its
-- PrimaryPart "Handle" sits at the weapon's origin); clients clone it for
-- their first-person view.
function MeleeModels.held(id: string, hand: BasePart): Model?
	if not SPECS[id] then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "Melee"
	model:SetAttribute("Weapon", id)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 0.2)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	-- Shaft pointing forward out of the fist, the hand round the grip.
	local c0 = CFrame.new(0, -0.2, 0) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.new(0, -MeleeModels.GRIP, 0)
	handle.CFrame = hand.CFrame * c0
	handle.Parent = model
	model.PrimaryPart = handle
	local weld = Instance.new("Weld")
	weld.Part0 = hand
	weld.Part1 = handle
	weld.C0 = c0
	weld.Parent = handle
	local prims = parts(id, handle.CFrame, model)
	for _, p in prims do
		p.Anchored = false
		p.Massless = true
		local w = Instance.new("Weld")
		w.Part0 = handle
		w.Part1 = p
		w.C0 = handle.CFrame:ToObjectSpace(p.CFrame)
		w.Parent = p
	end
	model.Parent = hand.Parent
	Meshes.attach(id, handle, CFrame.identity, {
		onBuilt = function()
			for _, p in prims do
				p:Destroy()
			end
		end,
	})
	return model
end

return MeleeModels
