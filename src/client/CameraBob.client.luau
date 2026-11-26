-- Gentle head bob while walking. Uses Humanoid.CameraOffset, so it works
-- in first and third person and costs almost nothing.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BOB_SPEED = 9 -- steps per second-ish
local BOB_HEIGHT = 0.12 -- studs up and down
local BOB_SWAY = 0.08 -- studs side to side

local player = Players.LocalPlayer
local t = 0
local strength = 0

RunService.RenderStepped:Connect(function(dt)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return
	end

	-- Fade the bob in and out with movement speed, so stopping feels smooth.
	local speed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
	local moving = humanoid.FloorMaterial ~= Enum.Material.Air and speed > 1
	local target = if moving then math.clamp(speed / 16, 0, 1.3) else 0
	strength += (target - strength) * math.min(dt * 8, 1)

	t += dt * BOB_SPEED * math.max(strength, 0.2)
	humanoid.CameraOffset = Vector3.new(
		math.sin(t) * BOB_SWAY * strength,
		math.abs(math.cos(t)) * BOB_HEIGHT * strength,
		0
	)
end)
