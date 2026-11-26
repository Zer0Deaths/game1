-- On-screen HUD: quota and timer at the top, carry load at the bottom,
-- short toasts for pickups and deposits, and a big banner for run events.
-- Reads Workspace attributes set by the server's RunManager.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent

local player = Players.LocalPlayer

local AMBER = Color3.fromRGB(255, 196, 110)
local PALE = Color3.fromRGB(235, 228, 200)
local RED = Color3.fromRGB(255, 90, 70)
local GREEN = Color3.fromRGB(150, 230, 120)
local FONT = Enum.Font.Code -- typewriter-ish, fits the found-footage office vibe

local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local function label(props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextColor3 = PALE
	l.TextStrokeTransparency = 0.5
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = props.Parent or gui
	return l
end

-- Top: quota and timer.
local quotaLabel = label({
	Name = "Quota",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(360, 26),
	TextSize = 22,
	TextColor3 = AMBER,
})
local timerLabel = label({
	Name = "Timer",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 34),
	Size = UDim2.fromOffset(200, 22),
	TextSize = 20,
})

-- Bottom: what you are carrying.
local carryLabel = label({
	Name = "Carry",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -78),
	Size = UDim2.fromOffset(420, 22),
	TextSize = 18,
})

-- Toasts: small messages stacking above the carry line.
local toastHolder = Instance.new("Frame")
toastHolder.Name = "Toasts"
toastHolder.BackgroundTransparency = 1
toastHolder.AnchorPoint = Vector2.new(0.5, 1)
toastHolder.Position = UDim2.new(0.5, 0, 1, -104)
toastHolder.Size = UDim2.fromOffset(520, 120)
toastHolder.Parent = gui
local layout = Instance.new("UIListLayout")
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = toastHolder

-- Banner: big centred text for run start and end.
local banner = label({
	Name = "Banner",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.32),
	Size = UDim2.new(0.9, 0, 0, 44),
	TextSize = 30,
	TextColor3 = AMBER,
	TextWrapped = true,
	TextTransparency = 1,
	TextStrokeTransparency = 1,
})

local toastCount = 0
local function toast(text: string, kind: string)
	toastCount += 1
	local t = label({
		Parent = toastHolder,
		LayoutOrder = toastCount,
		Size = UDim2.fromOffset(520, 22),
		TextSize = 17,
		Text = text,
		TextColor3 = if kind == "money" then GREEN elseif kind == "warn" then RED else PALE,
	})
	task.delay(3, function()
		TweenService:Create(t, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.7)
		t:Destroy()
	end)
end

local bannerToken = 0
local function showBanner(text: string)
	bannerToken += 1
	local mine = bannerToken
	banner.Text = text
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0.3
	task.delay(4, function()
		if mine == bannerToken then
			TweenService:Create(banner, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

Notify.OnClientEvent:Connect(function(text: string, kind: string)
	if kind == "banner" then
		showBanner(text)
	else
		toast(text, kind)
	end
end)

RunService.Heartbeat:Connect(function()
	local quota = workspace:GetAttribute("RunQuota") or 0
	local banked = workspace:GetAttribute("RunBanked") or 0
	quotaLabel.Text = `QUOTA  ${banked} / ${quota}`
	quotaLabel.TextColor3 = if banked >= quota and quota > 0 then GREEN else AMBER

	local endsAt = workspace:GetAttribute("RunEndsAt")
	if workspace:GetAttribute("RunState") == "playing" and endsAt then
		local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
		timerLabel.Text = string.format("%02d:%02d", left // 60, left % 60)
		timerLabel.TextColor3 = if left <= 60 then RED else PALE
	else
		timerLabel.Text = "--:--"
		timerLabel.TextColor3 = PALE
	end

	local count = player:GetAttribute("CarryCount") or 0
	local weight = player:GetAttribute("CarryWeight") or 0
	if count == 0 then
		carryLabel.Text = "Hands empty"
	else
		local slowed = weight * Config.SPEED_PER_WEIGHT >= 1
		carryLabel.Text = `Carrying {count}/{Config.MAX_CARRY}{if slowed then "  ·  slowed" else ""}  ·  [G] drop`
	end
end)
