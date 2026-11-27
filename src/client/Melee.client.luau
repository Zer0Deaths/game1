--!strict
-- Melee: the weapon in your hand from the lift armoury, seen in first
-- person, and the swing. Click (R2 on a pad, the Swing button on a phone)
-- to swing; the server (MeleeService) decides what it hit.
--
-- The weapon others see is welded into your character's right hand. Your
-- own copy of it is a clone held in front of the camera; it is moved to
-- the camera each frame, and only the weapon moves when you swing: the
-- camera and your aim are never touched.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ShopItems = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopItems"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Swing = Remotes:WaitForChild("Swing") :: RemoteEvent

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local byId: { [string]: ShopItems.Item } = {}
for _, item in ShopItems do
	if item.kind == "melee" then
		byId[item.id] = item
	end
end

-- Held low on the right, shaft up and leaning in.
local REST = CFrame.new(1.15, -1.55, -2.1) * CFrame.Angles(math.rad(-22), math.rad(-8), math.rad(24))
local SWING_TIME = 0.32

local view: Model? = nil
local source: Model? = nil
local dirty = false -- the hand copy changed (its Blender mesh arrived)
local watch: RBXScriptConnection? = nil
local swingAt = -math.huge
local lastSwing = -math.huge

-- HUD: the weapon and how many hits it has left.
local gui = Instance.new("ScreenGui")
gui.Name = "Melee"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(1, 1)
label.Position = UDim2.new(1, -18, 1, -200)
label.Size = UDim2.fromOffset(220, 20)
label.BackgroundTransparency = 1
label.Font = Enum.Font.Code
label.TextSize = 15
label.TextXAlignment = Enum.TextXAlignment.Right
label.TextColor3 = Color3.fromRGB(235, 228, 200)
label.TextStrokeTransparency = 0.5
label.Visible = false
label.Parent = gui

local function heldItem(): ShopItems.Item?
	local id = player:GetAttribute("Melee")
	return if typeof(id) == "string" then byId[id] else nil
end

local function clearView()
	if view then
		view:Destroy()
		view = nil
	end
	if watch then
		watch:Disconnect()
		watch = nil
	end
	source = nil
end

-- A frozen copy of the weapon in your hand, for the camera.
local function rebuildView()
	local character = player.Character
	local held = character and character:FindFirstChild("Melee") :: Model?
	clearView()
	if not held or not held.PrimaryPart then
		return
	end
	source = held
	dirty = false
	watch = held.DescendantAdded:Connect(function()
		dirty = true
	end)
	local copy = held:Clone()
	for _, d in copy:GetDescendants() do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
			d.Massless = true
		end
	end
	copy.Name = "MeleeView"
	copy.Parent = camera
	view = copy
end

-- 0..1 through a swing: a short wind-up, the strike, the recovery.
local function swingOffset(t: number): CFrame
	if t < 0 or t > 1 then
		return CFrame.identity
	end
	local back, down, across
	if t < 0.25 then
		local k = t / 0.25
		back, down, across = 35 * k, 0, 0.2 * k
	elseif t < 0.55 then
		local k = (t - 0.25) / 0.3
		k = 1 - (1 - k) ^ 3
		back, down, across = 35 - 115 * k, 0.5 * k, 0.2 - 1.1 * k
	else
		local k = (t - 0.55) / 0.45
		k = k * k * (3 - 2 * k)
		back, down, across = -80 * (1 - k), 0.5 * (1 - k), -0.9 * (1 - k)
	end
	return CFrame.new(across, -down, 0) * CFrame.Angles(math.rad(back), 0, math.rad(-across * 25))
end

RunService:BindToRenderStep("MeleeView", Enum.RenderPriority.Camera.Value + 1, function()
	local character = player.Character
	local held = character and character:FindFirstChild("Melee") :: Model?
	if held ~= source or dirty then
		rebuildView() -- new weapon, or its Blender mesh just arrived
	end
	local item = heldItem()
	label.Visible = item ~= nil
	if item then
		label.Text = `{string.upper(item.name)}  {player:GetAttribute("MeleeUses") or 0} hits`
	end
	if held then
		-- Hide the hand copy on this device only; others still see it.
		for _, d in held:GetDescendants() do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = 1
			end
		end
	end
	if view then
		local t = (os.clock() - swingAt) / SWING_TIME
		view:PivotTo(camera.CFrame * REST * swingOffset(t))
	end
end)

local function onSwing(_, state: Enum.UserInputState)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local item = heldItem()
	if not item then
		return Enum.ContextActionResult.Pass
	end
	local shop = player.PlayerGui:FindFirstChild("Shop") :: ScreenGui?
	if shop and shop.Enabled then
		return Enum.ContextActionResult.Pass
	end
	local spec = item.melee :: ShopItems.Melee
	local t = os.clock()
	if t - lastSwing < spec.cooldown then
		return Enum.ContextActionResult.Sink
	end
	lastSwing = t
	swingAt = t
	-- The hit lands at the strike, a moment into the swing.
	task.delay(SWING_TIME * 0.35, function()
		Swing:FireServer(camera.CFrame.LookVector)
	end)
	return Enum.ContextActionResult.Sink
end

-- Bound only while you hold a weapon, so clicks are left alone otherwise.
local bound = false
local function rebind()
	local want = heldItem() ~= nil
	if want and not bound then
		ContextActionService:BindAction("MeleeSwing", onSwing, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
		ContextActionService:SetTitle("MeleeSwing", "Swing")
		ContextActionService:SetPosition("MeleeSwing", UDim2.new(1, -160, 1, -95))
	elseif not want and bound then
		ContextActionService:UnbindAction("MeleeSwing")
	end
	bound = want
end
player:GetAttributeChangedSignal("Melee"):Connect(rebind)
rebind()
