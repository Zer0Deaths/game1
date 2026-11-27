--!strict
-- Your flashlight, on your own screen: a SpotLight fixed to the camera, so
-- the beam goes exactly where you look (with shadows). The server still
-- puts a light on your head so your crew sees your beam; on this device
-- that one is turned down so you don't get two.
-- When an entity is close, the beam stutters.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer

local holder = Instance.new("Part")
holder.Name = "FlashlightMount"
holder.Anchored = true
holder.CanCollide = false
holder.CanQuery = false
holder.CanTouch = false
holder.CastShadow = false
holder.Transparency = 1
holder.Size = Vector3.new(0.2, 0.2, 0.2)

local beam = Instance.new("SpotLight")
beam.Name = "Beam"
beam.Face = Enum.NormalId.Front
beam.Angle = 50
beam.Range = Config.FLASHLIGHT_RANGE
beam.Brightness = Config.FLASHLIGHT_BRIGHTNESS
beam.Color = Color3.fromRGB(255, 244, 214)
beam.Shadows = true
beam.Enabled = false
beam.Parent = holder

local function mount()
	holder.Parent = workspace.CurrentCamera
end
mount()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(mount)

local function entityNear(pos: Vector3): number
	local best = math.huge
	for _, inst in CollectionService:GetTagged("SHIFT_Tenant") do
		if inst:IsA("Model") and inst:IsDescendantOf(workspace) and inst:GetAttribute("Crew") == player:GetAttribute("Crew") then
			best = math.min(best, (inst:GetPivot().Position - pos).Magnitude)
		end
	end
	return best
end

local flickerUntil = 0
local nextFlicker = 0
RunService:BindToRenderStep("ShiftFlashlight", Enum.RenderPriority.Camera.Value + 2, function()
	local cam = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local on = player:GetAttribute("FlashlightOn") == true and humanoid ~= nil and humanoid.Health > 0
	-- The head light is for everyone else; hide it on this screen.
	local head = character and character:FindFirstChild("Head")
	local headLight = head and head:FindFirstChild("Flashlight")
	if headLight and headLight:IsA("SpotLight") and headLight.Brightness ~= 0 then
		headLight.Brightness = 0
	end
	if not on or not cam then
		beam.Enabled = false
		return
	end
	-- A touch below the eye, as if held at the chest.
	holder.CFrame = cam.CFrame * CFrame.new(0.3, -0.35, 0)

	local now = os.clock()
	local d = entityNear(cam.CFrame.Position)
	local danger = math.clamp(1 - (d - 12) / 40, 0, 1)
	if danger > 0 and now >= nextFlicker then
		-- The closer it is, the more often the beam stutters.
		nextFlicker = now + (1.4 - danger) * (0.3 + math.random() * 0.8)
		flickerUntil = now + 0.04 + math.random() * 0.12 * (0.5 + danger)
	end
	local flicker = now < flickerUntil
	beam.Enabled = true
	beam.Brightness = if flicker then Config.FLASHLIGHT_BRIGHTNESS * (math.random() < 0.5 and 0 or 0.25) else Config.FLASHLIGHT_BRIGHTNESS
end)
