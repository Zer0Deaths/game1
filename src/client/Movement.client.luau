-- Movement: walk speed, jump height, sprint and stamina, all shaped by
-- how much loot you carry (the server sets the player's CarryWeight
-- attribute). Runs on your own device so it feels instant.
--
-- Sprint: Left Shift, L3 on gamepad, or the "Sprint" button on phones.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer

local wantSprint = false
local stamina = 100
local exhausted = false
local lastSprintTime = 0

local function onSprint(_, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin then
		wantSprint = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		wantSprint = false
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("Sprint", onSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("Sprint", "Sprint")
ContextActionService:SetPosition("Sprint", UDim2.new(1, -230, 1, -95))

-- Stamina bar: thin strip near the bottom, fades out when full.
local gui = Instance.new("ScreenGui")
gui.Name = "Stamina"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local back = Instance.new("Frame")
back.AnchorPoint = Vector2.new(0.5, 1)
back.Position = UDim2.new(0.5, 0, 1, -62)
back.Size = UDim2.fromOffset(240, 6)
back.BackgroundColor3 = Color3.fromRGB(20, 18, 12)
back.BackgroundTransparency = 0.3
back.BorderSizePixel = 0
back.Parent = gui
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(235, 228, 200)
fill.BorderSizePixel = 0
fill.Parent = back

RunService.RenderStepped:Connect(function(dt)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local weight = player:GetAttribute("CarryWeight") or 0
	local moving = humanoid.MoveDirection.Magnitude > 0.1
	local now = os.clock()

	-- Sprinting drains faster the more you carry.
	local sprinting = wantSprint and moving and not exhausted and stamina > 0
	if sprinting then
		stamina -= (Config.STAMINA_DRAIN + weight * Config.STAMINA_DRAIN_PER_WEIGHT) * dt
		lastSprintTime = now
		if stamina <= 0 then
			stamina = 0
			exhausted = true
		end
	elseif now - lastSprintTime > Config.STAMINA_REGEN_DELAY then
		-- ...and you get your breath back slower under load.
		stamina += Config.STAMINA_REGEN / (1 + weight * Config.STAMINA_REGEN_PER_WEIGHT) * dt
		stamina = math.min(stamina, 100)
		if exhausted and stamina >= Config.EXHAUSTED_UNTIL then
			exhausted = false
		end
	end

	local walk = math.max(Config.MIN_WALK_SPEED, Config.WALK_SPEED - weight * Config.SPEED_PER_WEIGHT)
	humanoid.WalkSpeed = if sprinting then walk * Config.SPRINT_MULTIPLIER else walk
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = math.max(Config.MIN_JUMP_HEIGHT, Config.JUMP_HEIGHT - weight * Config.JUMP_PER_WEIGHT)

	-- Bar: amber when exhausted, hidden when full.
	fill.Size = UDim2.fromScale(stamina / 100, 1)
	fill.BackgroundColor3 = if exhausted then Color3.fromRGB(255, 120, 70) else Color3.fromRGB(235, 228, 200)
	back.Visible = stamina < 99.5
end)
