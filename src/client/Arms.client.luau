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

if not Config.SHOW_FIRST_PERSON_ARMS then
	return -- hidden until a proper arms model exists; flip the flag in Config to test
end

local player = Players.LocalPlayer

local R15_ARMS = {
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
}
local R6_ARMS = { "Right Arm", "Left Arm" }

-- A shoulder is either a classic Motor6D (we rotate its C0) or, with
-- Roblox's newer avatar joints, an AnimationConstraint (we rotate the
-- torso-side attachment instead, which has the same effect).
-- r6: R6 shoulders bend around their own Z axis instead of X.
type Shoulder = {
	motor: Motor6D?,
	attachment: Attachment?,
	base: CFrame,
	side: number,
	raise: number,
	r6: boolean,
}

local function setFrame(s: Shoulder, cf: CFrame)
	if s.motor then
		s.motor.C0 = cf
	elseif s.attachment then
		s.attachment.CFrame = cf
	end
end

local shoulders: { Shoulder } = {}
local armParts: { BasePart } = {}
local generation = 0

local function restore()
	for _, s in shoulders do
		setFrame(s, s.base)
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
	local kinds = {}
	for _, info in joints do
		local holder = character:WaitForChild(info[1] :: string, 10)
		local joint = holder and holder:WaitForChild(info[2] :: string, 10)
		table.insert(kinds, if joint then joint.ClassName else "missing")
		local entry: Shoulder? = nil
		if joint and joint:IsA("Motor6D") then
			entry = { motor = joint, base = joint.C0, side = info[3] :: number, raise = math.rad(A.idleRaise), r6 = r6 }
		elseif joint and joint:IsA("AnimationConstraint") then
			-- Use whichever end of the joint sits on the torso, not the arm.
			local a0, a1 = joint.Attachment0, joint.Attachment1
			local torsoSide = if a0 and a0.Parent ~= holder then a0 elseif a1 and a1.Parent ~= holder then a1 else nil
			if torsoSide then
				entry = { attachment = torsoSide, base = torsoSide.CFrame, side = info[3] :: number, raise = math.rad(A.idleRaise), r6 = r6 }
			end
		end
		if entry then
			table.insert(newShoulders, entry)
		end
	end
	if mine ~= generation then
		return -- a newer character arrived while we waited
	end
	armParts = found
	shoulders = newShoulders
	print(`[Arms] rig={if r6 then "R6" else "R15"} arm parts={#armParts} shoulders={#shoulders} joints={table.concat(kinds, ",")}`)
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
			setFrame(s, s.base * CFrame.Angles(0, 0, (s.raise + pitch) * s.side))
		else
			setFrame(
				s,
				s.base * CFrame.Angles(0, math.rad(A.inward) * s.side, 0) * CFrame.Angles(s.raise + pitch, 0, 0)
			)
		end
	end
end)
