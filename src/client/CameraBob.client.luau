-- Head bob, sway and lean that sell the weight you carry.
-- Empty-handed: a light, quick bob. Loaded: slower, deeper steps, the
-- camera rolls side to side and tips down, like hauling a heavy box.
-- Sprinting bobs faster. Low stamina adds a slow "breathing" heave.
--
-- Position bob uses Humanoid.CameraOffset. Roll and tilt are applied
-- right after Roblox's camera update each frame, so they never pile up.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local t = 0
local strength = 0 -- 0 standing still .. ~1.3 full speed
local load = 0 -- smoothed 0..1 from carry weight

local function frameData(dt: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return nil
	end
	local weight = player:GetAttribute("CarryWeight") or 0
	load += (math.clamp(weight / 14, 0, 1) - load) * math.min(dt * 3, 1)

	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local target = if grounded and speed > 1 then math.clamp(speed / 14, 0, 1.3) else 0
	strength += (target - strength) * math.min(dt * 8, 1)
	return humanoid
end

RunService.RenderStepped:Connect(function(dt)
	local humanoid = frameData(dt)
	if not humanoid then
		return
	end
	local sprinting = player:GetAttribute("Sprinting") == true
	-- Heavy loads slow the step rhythm; sprinting quickens it.
	local stepRate = (if sprinting then 12 else 8.5) * (1 - load * 0.35)
	t += dt * stepRate * math.max(strength, 0.15)

	local height = 0.12 + load * 0.22 -- deeper dip when loaded
	local sway = 0.08 + load * 0.16
	humanoid.CameraOffset = Vector3.new(
		math.sin(t) * sway * strength,
		(math.abs(math.cos(t)) - 0.5) * height * strength - load * 0.35, -- crouch a touch under load
		0
	)
end)

-- Roll and tilt, applied after the default camera has done its work.
RunService:BindToRenderStep("WeightLean", Enum.RenderPriority.Camera.Value + 1, function()
	local stamina = player:GetAttribute("Stamina") or 100
	local tired = math.clamp((40 - stamina) / 40, 0, 1)
	local breathe = math.sin(os.clock() * 2.2) * tired * math.rad(0.8)
	local roll = math.sin(t) * math.rad(0.6 + load * 2.4) * strength
	local tilt = -math.rad(load * 3) + breathe -- head tips down under load
	camera.CFrame *= CFrame.Angles(tilt, 0, roll)
end)
