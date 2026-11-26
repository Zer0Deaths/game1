--!strict
-- First-person arms, using YOUR real avatar arms (your shirt and skin).
-- Roblox hides your whole body in first person; this un-hides the arms and
-- hands, then lifts them forward at the shoulder (on this device only, other
-- players see you normally). The normal walk/run animation does the swing,
-- so it's subtle at walk and quicker when sprinting. The camera is never
-- touched. Angles live in Config.ARMS. Works with R15 and R6 bodies.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local A = Config.ARMS

local player = Players.LocalPlayer

local R15_ARMS = {
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
}
local R6_ARMS = { "Right Arm", "Left Arm" }

-- r6: R6 shoulders bend around their own Z axis instead of X.
type Shoulder = { motor: Motor6D, base: CFrame, side: number, raise: number, r6: boolean }

local shoulders: { Shoulder } = {}
local armParts: { BasePart } = {}
local generation = 0

local function restore()
	for _, s in shoulders do
		if s.motor.Parent then
			s.motor.C0 = s.base
		end
	end
	table.clear(shoulders)
	table.clear(armParts)
end

local function setup(character: Model)
	restore()
	generation += 1
	local mine = generation
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid or mine ~= generation then
		return
	end
	local r6 = humanoid.RigType == Enum.HumanoidRigType.R6
	local found: { BasePart } = {}
	for _, name in (if r6 then R6_ARMS else R15_ARMS) do
		local part = character:WaitForChild(name, 10)
		if part and part:IsA("BasePart") then
			table.insert(found, part)
		end
	end
	local joints = if r6
		then { { "Torso", "Right Shoulder", 1 }, { "Torso", "Left Shoulder", -1 } }
		else { { "RightUpperArm", "RightShoulder", 1 }, { "LeftUpperArm", "LeftShoulder", -1 } }
	local newShoulders: { Shoulder } = {}
	for _, info in joints do
		local holder = character:WaitForChild(info[1] :: string, 10)
		local motor = holder and holder:WaitForChild(info[2] :: string, 10)
		if motor and motor:IsA("Motor6D") then
			table.insert(newShoulders, {
				motor = motor,
				base = motor.C0,
				side = info[3] :: number,
				raise = math.rad(A.idleRaise),
				r6 = r6,
			})
		end
	end
	if mine ~= generation then
		return -- a newer character arrived while we waited
	end
	armParts = found
	shoulders = newShoulders
	print(`[Arms] rig={if r6 then "R6" else "R15"} arm parts={#armParts} shoulders={#shoulders}`)
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
		-- Suit details attached to the arm (tape) show too.
		for _, child in part:GetChildren() do
			if child:IsA("BasePart") then
				child.LocalTransparencyModifier = 0
			end
		end
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
		if s.r6 then
			-- R6: the right shoulder lifts forward with +Z, the left with -Z.
			s.motor.C0 = s.base * CFrame.Angles(0, 0, (s.raise + pitch) * s.side)
		else
			s.motor.C0 = s.base
				* CFrame.Angles(0, math.rad(A.inward) * s.side, 0)
				* CFrame.Angles(s.raise + pitch, 0, 0)
		end
	end
end)
