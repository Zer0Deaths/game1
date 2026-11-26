--!strict
-- Uniform: everyone spawns in the same SHIFT crew suit instead of their own
-- avatar. Built from basic parts and colours (no uploaded models): a teal
-- work suit, dark rubber gloves and boots, reflective tape on the forearms
-- and shins, a hood with a dark visor, and a "SHIFT" crew patch on the chest.
-- A proper modelled suit would need a Creator Store asset or a modeller.
--
-- Tape is parented to the arm parts so the first-person arms (Arms.client)
-- show it too.

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local Uniform = {}

local SUIT = Color3.fromRGB(58, 92, 88) -- oxidised teal: stands out against the yellow levels
local RUBBER = Color3.fromRGB(32, 32, 30) -- gloves and boots
local TAPE = Color3.fromRGB(205, 200, 180) -- worn reflective tape
local VISOR = Color3.fromRGB(20, 24, 24)
local PATCH = Color3.fromRGB(232, 168, 56) -- amber, the game's accent colour

local SUIT_PARTS = {
	"UpperTorso", "LowerTorso", "RightUpperArm", "RightLowerArm", "LeftUpperArm", "LeftLowerArm",
	"RightUpperLeg", "RightLowerLeg", "LeftUpperLeg", "LeftLowerLeg", "Head",
	-- R6 fallback
	"Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg",
}
local RUBBER_PARTS = { "RightHand", "LeftHand", "RightFoot", "LeftFoot" }

local function weldTo(part: BasePart, to: BasePart, offset: CFrame)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = to.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = to
	weld.Part1 = part
	weld.Parent = part
	part.Parent = to
end

local function band(limb: BasePart, along: number)
	-- A strip of tape wrapped round a limb, `along` studs from its centre.
	local size = limb.Size
	local tape = Instance.new("Part")
	tape.Name = "Tape"
	tape.Size = Vector3.new(size.X + 0.06, 0.16, size.Z + 0.06)
	tape.Color = TAPE
	tape.Material = Enum.Material.SmoothPlastic
	weldTo(tape, limb, CFrame.new(0, along, 0))
end

local function dress(character: Model)
	-- Strip anything from the player's own avatar.
	for _, item in character:GetChildren() do
		if item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
			item:Destroy()
		end
	end
	local head = character:FindFirstChild("Head")
	local face = head and head:FindFirstChild("face")
	if face then
		face:Destroy()
	end

	for _, name in SUIT_PARTS do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = SUIT
			part.Material = Enum.Material.Fabric
		end
	end
	for _, name in RUBBER_PARTS do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = RUBBER
			part.Material = Enum.Material.SmoothPlastic
		end
	end

	-- Reflective tape on forearms and shins.
	for _, name in { "RightLowerArm", "LeftLowerArm", "RightLowerLeg", "LeftLowerLeg" } do
		local limb = character:FindFirstChild(name)
		if limb and limb:IsA("BasePart") then
			band(limb, -limb.Size.Y * 0.15)
		end
	end

	-- Hood and visor over the head.
	if head and head:IsA("BasePart") then
		local hood = Instance.new("Part")
		hood.Name = "Hood"
		hood.Size = head.Size * Vector3.new(1.35, 1.3, 1.35)
		hood.Color = SUIT
		hood.Material = Enum.Material.Fabric
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = hood
		weldTo(hood, head, CFrame.new(0, 0.05, 0.05))

		local visor = Instance.new("Part")
		visor.Name = "Visor"
		visor.Size = Vector3.new(head.Size.X * 1.05, head.Size.Y * 0.45, 0.12)
		visor.Color = VISOR
		visor.Material = Enum.Material.Glass
		visor.Reflectance = 0.25
		weldTo(visor, head, CFrame.new(0, 0.08, -head.Size.Z * 0.62))
	end

	-- Crew patch on the chest.
	local chest = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if chest and chest:IsA("BasePart") then
		local gui = Instance.new("SurfaceGui")
		gui.Name = "CrewPatch"
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(200, 200)
		gui.LightInfluence = 1
		local label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0, 0)
		label.Position = UDim2.fromScale(0.52, 0.12)
		label.Size = UDim2.fromScale(0.4, 0.16)
		label.BackgroundColor3 = Color3.fromRGB(28, 26, 20)
		label.BorderSizePixel = 0
		label.Font = Enum.Font.Code
		label.Text = "SHIFT"
		label.TextScaled = true
		label.TextColor3 = PATCH
		label.Parent = gui
		gui.Parent = chest
	end
	print(`[Uniform] dressed {character.Name} in the crew suit`)
end

function Uniform.init()
	-- Spawn the plain default body instead of loading each player's avatar.
	StarterPlayer.LoadCharacterAppearance = false
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			-- Give the body a moment to finish assembling.
			character:WaitForChild("Humanoid", 10)
			task.wait()
			dress(character)
		end)
		if player.Character then
			dress(player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return Uniform
