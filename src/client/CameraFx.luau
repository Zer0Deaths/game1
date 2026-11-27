--!strict
-- CameraFx: head bob, sprint FOV kick, camera shake on big moments, and the
-- slight tilt at low sanity. ModuleScript shared by the client scripts.
--
-- SAFETY (Jason's earlier "view keeps getting pulled down" bug): Roblox's
-- camera script works out the next frame from the camera's current
-- CFrame, so any offset left on the camera gets fed back in and drifts
-- your aim. This module therefore:
--   1. removes last frame's offset just BEFORE the camera script runs,
--   2. adds this frame's offset just AFTER it, and
--   3. only ever offsets position and roll, never pitch or yaw, so where
--      you look is never changed, even for one frame.
-- Every effect decays to exactly zero. Field of view goes back to the
-- base value the moment nothing is kicking it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraFx = {}

local player = Players.LocalPlayer
local BASE_FOV = 70

-- Tuning (all small on purpose).
local BOB_HEIGHT = 0.055 -- studs up/down per step
local BOB_SIDE = 0.035
local BOB_ROLL = math.rad(0.25)
local SPRINT_FOV = 5 -- degrees wider while sprinting
local MAX_TILT = math.rad(2.2) -- at zero sanity

local applied = CFrame.identity -- the offset currently on the camera
local shakes: { { strength: number, untilT: number, length: number } } = {}
local kick = 0 -- current FOV kick in degrees (decays)
local sprintFov = 0
local bobPhase = 0
local bobAmount = 0
local tiltPhase = math.random() * 10

-- A short shake: strength in studs (0.1 small, 0.3 big), seconds long.
function CameraFx.shake(strength: number, seconds: number)
	table.insert(shakes, { strength = strength, untilT = os.clock() + seconds, length = seconds })
end

-- A quick widening of the view that eases back (degrees).
function CameraFx.kick(degrees: number)
	kick = math.max(kick, degrees)
end

local function camera(): Camera?
	return workspace.CurrentCamera
end

-- 1. Before the camera script: take last frame's offset off again.
RunService:BindToRenderStep("ShiftCameraFxUndo", Enum.RenderPriority.Camera.Value - 1, function()
	local cam = camera()
	if cam and applied ~= CFrame.identity then
		cam.CFrame = cam.CFrame * applied:Inverse()
	end
	applied = CFrame.identity
end)

-- 2. After the camera script: put this frame's offset on.
RunService:BindToRenderStep("ShiftCameraFxApply", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local cam = camera()
	if not cam then
		return
	end
	local now = os.clock()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local alive = humanoid ~= nil and humanoid.Health > 0

	-- Head bob: only while walking on the ground, scaled by speed.
	local speed = 0
	if alive and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local v = root.AssemblyLinearVelocity
			speed = Vector3.new(v.X, 0, v.Z).Magnitude
		end
	end
	local targetBob = math.clamp(speed / 16, 0, 1.6)
	bobAmount += (targetBob - bobAmount) * math.min(1, dt * 8)
	bobPhase += dt * (5 + speed * 0.32)
	local by = math.abs(math.sin(bobPhase)) * BOB_HEIGHT * 2 - BOB_HEIGHT
	local bx = math.cos(bobPhase) * BOB_SIDE
	local roll = math.cos(bobPhase) * BOB_ROLL * bobAmount
	local pos = Vector3.new(bx, by, 0) * bobAmount

	-- Shake: random position jitter, fading out over its length.
	local strength = 0
	for i = #shakes, 1, -1 do
		local s = shakes[i]
		if now >= s.untilT then
			table.remove(shakes, i)
		else
			strength = math.max(strength, s.strength * ((s.untilT - now) / s.length) ^ 2)
		end
	end
	if strength > 0.001 then
		pos += Vector3.new((math.random() * 2 - 1) * strength, (math.random() * 2 - 1) * strength, 0)
		roll += (math.random() * 2 - 1) * strength * 0.05
	end

	-- Low sanity: a slow, slight lean that drifts side to side.
	local sanity = (player:GetAttribute("Sanity") or 100) :: number
	local lean = math.clamp((50 - sanity) / 50, 0, 1)
	tiltPhase += dt * 0.35
	roll += math.sin(tiltPhase) * MAX_TILT * lean

	if not alive then
		pos, roll = Vector3.zero, 0
	end
	local offset = CFrame.new(pos) * CFrame.Angles(0, 0, roll)
	cam.CFrame = cam.CFrame * offset
	applied = offset

	-- Field of view: sprint widening plus any kick, easing back to exactly base.
	local sprinting = alive and player:GetAttribute("Sprinting") == true and speed > 18
	sprintFov += ((if sprinting then SPRINT_FOV else 0) - sprintFov) * math.min(1, dt * 6)
	kick = math.max(0, kick - dt * 14)
	local extra = sprintFov + kick
	if extra < 0.02 then
		extra, sprintFov = 0, 0
	end
	cam.FieldOfView = BASE_FOV + extra
end)

return CameraFx
