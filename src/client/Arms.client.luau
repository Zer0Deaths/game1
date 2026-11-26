--!strict
-- First-person arms, using YOUR real avatar arms (your shirt and skin).
-- Roblox hides your whole body in first person; this un-hides the arms and
-- hands, then lifts them forward at the shoulder (on this device only, other
-- players see you normally). The normal walk/run animation does the swing,
-- so it's subtle at walk and quicker when sprinting. The camera is never
-- touched. Angles live in Config.ARMS. Needs an R15 avatar (Studio default).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local A = Config.ARMS

local player = Players.LocalPlayer

local ARM_PARTS = {
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
}

type Shoulder = { motor: Motor6D, base: CFrame, side: number, raise: number }

local shoulders: { Shoulder } = {}
local armParts: { BasePart } = {}

local function setup(character: Model)
	-- Put any previous character's shoulders back first.
	for _, s in shoulders do
		if s.motor.Parent then
			s.motor.C0 = s.base
		end
	end
	table.clear(shoulders)
	table.clear(armParts)

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	for _, name in ARM_PARTS do
		local part = character:WaitForChild(name, 10)
		if part and part:IsA("BasePart") then
			table.insert(armParts, part)
		end
	end
	for _, info in { { "RightUpperArm", "RightShoulder", 1 }, { "LeftUpperArm", "LeftShoulder", -1 } } do
		local arm = character:FindFirstChild(info[1] :: string)
		local motor = arm and arm:WaitForChild(info[2] :: string, 10)
		if motor and motor:IsA("Motor6D") then
			table.insert(shoulders, { motor = motor, base = motor.C0, side = info[3] :: number, raise = math.rad(A.idleRaise) })
		end
	end
end

player.CharacterAdded:Connect(setup)
if player.Character then
	task.spawn(setup, player.Character)
end

-- Runs right after Roblox's camera, which is what hides the body.
RunService:BindToRenderStep("FirstPersonArms", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local camera = workspace.CurrentCamera
	if not character or not humanoid or not root or not camera or humanoid.Health <= 0 or #shoulders == 0 then
		return
	end

	for _, part in armParts do
		part.LocalTransparencyModifier = 0
	end

	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local target = if speed > Config.WALK_SPEED * 1.15
		then A.sprintRaise
		elseif speed > 1.5 then A.walkRaise
		else A.idleRaise
	local pitch = math.asin(math.clamp(camera.CFrame.LookVector.Y, -1, 1)) * A.lookFollow
	local holdingTool = character:FindFirstChildOfClass("Tool") ~= nil
	local blend = math.min(1, dt * A.ease)

	for _, s in shoulders do
		-- Holding loot: Roblox's hold animation already lifts the right arm.
		local wanted = if holdingTool and s.side > 0 then 0 else math.rad(target)
		s.raise += (wanted - s.raise) * blend
		s.motor.C0 = s.base
			* CFrame.Angles(0, math.rad(A.inward) * s.side, 0)
			* CFrame.Angles(s.raise + pitch, 0, 0)
	end
end)
