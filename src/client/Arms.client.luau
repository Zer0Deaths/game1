--!strict
-- First-person arms. Two simple arms drawn in front of your own camera
-- (only you see them; everyone else sees your normal character). They rise
-- into view and pump when you walk, pump harder and faster when you sprint,
-- and sink out of view when you stand still. Only the arms move: the camera
-- is never touched.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local SLEEVE = Color3.fromRGB(58, 56, 44) -- worn work jacket
local DEFAULT_SKIN = Color3.fromRGB(204, 160, 120)

local STEP_RATE = 0.8 -- swing radians per stud travelled
local REST_DROP = 1.6 -- how far below view the arms sink when still

local function makePart(name: string, size: Vector3, colour: Color3, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = colour
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

type Arm = { sleeve: BasePart, hand: BasePart, side: number }

local folder = Instance.new("Folder")
folder.Name = "FirstPersonArms"

local function makeArm(side: number): Arm
	local sleeve = makePart("Sleeve", Vector3.new(0.5, 0.5, 1.9), SLEEVE, folder)
	local hand = makePart("Hand", Vector3.new(0.42, 0.32, 0.5), DEFAULT_SKIN, folder)
	return { sleeve = sleeve, hand = hand, side = side }
end

local arms = { makeArm(-1), makeArm(1) }

local function skinColour(): Color3
	local character = player.Character
	local part = character
		and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?
	return if part then part.Color else DEFAULT_SKIN
end

local phase = 0
local amount = 0 -- 0 = arms hidden below view, 1 = fully up and swinging

RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not camera or not humanoid or not root or humanoid.Health <= 0 then
		folder.Parent = nil
		return
	end
	folder.Parent = camera

	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local moving = speed > 1.5 and grounded

	-- Ease the arms up when moving, down when standing still.
	amount += ((if moving then 1 else 0) - amount) * math.min(1, dt * 6)
	-- Faster and bigger swings at sprint speed.
	local effort = math.clamp(speed / 16, 0, 1.8)
	phase = (phase + speed * STEP_RATE * dt) % (math.pi * 2)

	local skin = skinColour()
	for _, arm in arms do
		local swing = math.sin(phase + (if arm.side > 0 then 0 else math.pi))
		local reach = swing * 0.35 * effort -- forward/back pump
		local lift = math.abs(swing) * 0.12 * effort
		local base = CFrame.new(arm.side * 0.85, -1.15 - (1 - amount) * REST_DROP + lift, -1.1 - reach)
		local angle = CFrame.Angles(math.rad(15 + swing * 10 * effort), math.rad(-arm.side * 8), math.rad(arm.side * 4))
		local sleeveCf = camera.CFrame * base * angle
		arm.sleeve.CFrame = sleeveCf
		arm.hand.CFrame = sleeveCf * CFrame.new(0, 0, -1.15)
		arm.hand.Color = skin
		local hidden = amount < 0.02
		arm.sleeve.LocalTransparencyModifier = if hidden then 1 else 0
		arm.hand.LocalTransparencyModifier = if hidden then 1 else 0
	end
end)
