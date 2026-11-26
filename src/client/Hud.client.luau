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
	Size = UDim2.fromOffset(460, 26),
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

-- Bottom-left: what you are carrying. Kept out of the centre of the
-- screen so it never sits under a "Pick up" prompt.
local carryLabel = label({
	Name = "Carry",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 20, 1, -32),
	Size = UDim2.fromOffset(420, 22),
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- Bottom-right: your own money (spent in the safehouse shop).
local cashLabel = label({
	Name = "Cash",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -32),
	Size = UDim2.fromOffset(240, 22),
	TextSize = 18,
	TextColor3 = GREEN,
	TextXAlignment = Enum.TextXAlignment.Right,
})

-- Toasts: small messages stacking above the carry line.
local toastHolder = Instance.new("Frame")
toastHolder.Name = "Toasts"
toastHolder.BackgroundTransparency = 1
toastHolder.AnchorPoint = Vector2.new(0, 1)
toastHolder.Position = UDim2.new(0, 20, 1, -58) -- bottom-left above the carry line, clear of prompts
toastHolder.Size = UDim2.fromOffset(520, 120)
toastHolder.Parent = gui
local layout = Instance.new("UIListLayout")
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
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
		TextXAlignment = Enum.TextXAlignment.Left,
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
	local crew = player:GetAttribute("Crew") or 1
	local quota = workspace:GetAttribute(`Crew{crew}Quota`) or 0
	local banked = workspace:GetAttribute(`Crew{crew}Banked`) or 0
	quotaLabel.Text = `{string.upper(Config.CREW_NAMES[crew] or "CREW")}  ${banked} / ${quota}`
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

	cashLabel.Text = `CASH  ${player:GetAttribute("Cash") or 0}`

	local count = player:GetAttribute("CarryCount") or 0
	local weight = player:GetAttribute("CarryWeight") or 0
	if count == 0 then
		carryLabel.Text = "Hands empty  ·  [Shift] sprint"
	else
		local load = if weight >= 10 then "very heavy" elseif weight >= 5 then "heavy" elseif weight >= 2 then "loaded" else "light"
		carryLabel.Text = `Carrying {count}/{Config.MAX_CARRY + (player:GetAttribute("CarryBonus") or 0)}  ·  {load}  ·  [G] drop  [Shift] sprint`
	end
end)
