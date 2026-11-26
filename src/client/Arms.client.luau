--!strict
-- First-person arms. Two smooth, lowered arms (jacket sleeve + hand) drawn
-- in front of your own camera; only you see them. They sit low in the bottom
-- corners while you walk with a short, slow swing, lean in a little and pump
-- harder when you sprint, and sink out of view when you stand still.
-- Only the arms move: the camera is never touched.
-- Every position and swing number lives in Config.ARMS for tuning.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local A = Config.ARMS

local player = Players.LocalPlayer

local SLEEVE = Color3.fromRGB(52, 50, 40) -- worn work jacket
local CUFF = Color3.fromRGB(40, 38, 30)
local DEFAULT_SKIN = Color3.fromRGB(196, 154, 118)

-- A smooth rounded shape: a Part with an ellipsoid mesh that fills its size.
local function makeShape(name: string, size: Vector3, colour: Color3, material: Enum.Material, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = colour
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	p.Parent = parent
	return p
end

type Arm = { side: number, sleeve: BasePart, cuff: BasePart, hand: BasePart, fingers: BasePart }

local folder = Instance.new("Folder")
folder.Name = "FirstPersonArms"

local function makeArm(side: number): Arm
	return {
		side = side,
		sleeve = makeShape("Sleeve", Vector3.new(0.36, 0.34, 1.7), SLEEVE, Enum.Material.Fabric, folder),
		cuff = makeShape("Cuff", Vector3.new(0.3, 0.28, 0.22), CUFF, Enum.Material.Fabric, folder),
		hand = makeShape("Hand", Vector3.new(0.24, 0.13, 0.3), DEFAULT_SKIN, Enum.Material.SmoothPlastic, folder),
		fingers = makeShape("Fingers", Vector3.new(0.22, 0.1, 0.22), DEFAULT_SKIN, Enum.Material.SmoothPlastic, folder),
	}
end

local arms = { makeArm(-1), makeArm(1) }

local function skinColour(): Color3
	local character = player.Character
	local part = character
		and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?
	return if part then part.Color else DEFAULT_SKIN
end

local phase = 0
local shown = 0 -- 0 = sunk out of view, 1 = in position
local sprint = 0 -- 0 = walking, 1 = full sprint
local swingSize = 0 -- eased swing amplitude

local function ease(current: number, target: number, dt: number): number
	return current + (target - current) * math.min(1, dt * A.ease)
end

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
	local moving = speed > 1.5
	-- Sprinting = moving well above normal walk speed.
	local sprinting = speed > Config.WALK_SPEED * 1.15

	shown = ease(shown, if moving then 1 else 0, dt)
	sprint = ease(sprint, if sprinting then 1 else 0, dt)
	swingSize = ease(swingSize, if moving and grounded then 1 else 0, dt)
	if grounded then
		phase = (phase + speed * A.stepRate * dt) % (math.pi * 2)
	end

	local amplitude = (A.swing + (A.sprintSwing - A.swing) * sprint) * swingSize
	local skin = skinColour()
	local hidden = shown < 0.02
	for _, arm in arms do
		local s = math.sin(phase + (if arm.side > 0 then 0 else math.pi))
		local x = arm.side * A.x
		local y = A.y + A.sprintRaise * sprint - (1 - shown) * A.hideDrop + math.abs(s) * amplitude * 0.25
		local z = A.z + A.sprintPull * sprint - s * amplitude
		local pitch = A.pitch + A.sprintPitch * sprint + s * A.swingTilt * swingSize
		local sleeveCf = camera.CFrame
			* CFrame.new(x, y, z)
			* CFrame.Angles(math.rad(pitch), math.rad(arm.side * A.yaw), math.rad(-arm.side * 6))
		arm.sleeve.CFrame = sleeveCf
		arm.cuff.CFrame = sleeveCf * CFrame.new(0, 0, -0.82)
		arm.hand.CFrame = sleeveCf * CFrame.new(0, -0.01, -1.02) * CFrame.Angles(math.rad(-6), 0, math.rad(arm.side * 12))
		arm.fingers.CFrame = arm.hand.CFrame * CFrame.new(-arm.side * 0.01, -0.02, -0.17) * CFrame.Angles(math.rad(-25), 0, 0)
		arm.hand.Color = skin
		arm.fingers.Color = skin
		for _, part in { arm.sleeve, arm.cuff, arm.hand, arm.fingers } do
			part.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end)
