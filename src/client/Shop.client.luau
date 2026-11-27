--!strict
-- The shop screen: the safehouse supplies counter, or the armoury in the
-- exit lift (OpenShop fires with "lift": melee weapons only). Buying is
-- checked by the server (ShopService); this only shows what's on offer.
-- Also: F toggles your flashlight once you own one.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ShopItems = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopItems"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OpenShop = Remotes:WaitForChild("OpenShop") :: RemoteEvent
local BuyItem = Remotes:WaitForChild("BuyItem") :: RemoteEvent
local ToggleFlashlight = Remotes:WaitForChild("ToggleFlashlight") :: RemoteEvent
local Audio = require(script.Parent:WaitForChild("Audio"))

local player = Players.LocalPlayer
local AMBER = Color3.fromRGB(255, 196, 110)
local PALE = Color3.fromRGB(235, 228, 200)
local GREEN = Color3.fromRGB(150, 230, 120)
local GREY = Color3.fromRGB(120, 116, 104)

local gui = Instance.new("ScreenGui")
gui.Name = "Shop"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(460, 96 + 4 * 78)
panel.BackgroundColor3 = Color3.fromRGB(18, 16, 12)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Parent = gui
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

local function openPanel()
	panelScale.Scale = 0.9
	gui.Enabled = true
	TweenService:Create(panelScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end
local function closePanel()
	local t = TweenService:Create(panelScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.92 })
	t:Play()
	t.Completed:Once(function()
		gui.Enabled = false
	end)
end

-- Buttons lean in under the mouse and press down when clicked.
local function juice(button: GuiButton)
	local s = Instance.new("UIScale")
	s.Parent = button
	local function to(v: number, seconds: number)
		TweenService:Create(s, TweenInfo.new(seconds, Enum.EasingStyle.Quad), { Scale = v }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.05, 0.12)
	end)
	button.MouseLeave:Connect(function()
		to(1, 0.12)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.94, 0.06)
	end)
	button.MouseButton1Up:Connect(function()
		to(1.05, 0.1)
	end)
end

local function text(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code
	l.TextColor3 = PALE
	l.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

local title = text(panel, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -120, 0, 26), TextSize = 20, TextColor3 = AMBER, Text = "SUPPLIES" })
local cashText = text(panel, { Position = UDim2.new(1, -220, 0, 12), Size = UDim2.fromOffset(200, 22), TextSize = 16, TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Right })

-- Modal so the mouse is freed from first person while the shop is open.
local close = Instance.new("TextButton")
close.Modal = true
close.AnchorPoint = Vector2.new(0.5, 1)
close.Position = UDim2.new(0.5, 0, 1, -12)
close.Size = UDim2.fromOffset(140, 30)
close.BackgroundColor3 = Color3.fromRGB(50, 46, 36)
close.BorderSizePixel = 0
close.Font = Enum.Font.Code
close.TextSize = 16
close.TextColor3 = PALE
close.Text = "Close"
close.Parent = panel
juice(close)
close.Activated:Connect(function()
	Audio.ui("UI_CLOSE")
	closePanel()
end)

type Row = { item: ShopItems.Item, frame: Frame, button: TextButton, status: TextLabel }
local rows: { Row } = {}
local mode = "safehouse"

local function rowFor(item: ShopItems.Item): Row
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -24, 0, 70)
	row.BackgroundColor3 = Color3.fromRGB(32, 29, 22)
	row.BorderSizePixel = 0
	row.Visible = false
	row.Parent = panel
	text(row, { Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -140, 0, 20), TextSize = 17, TextColor3 = AMBER, Text = item.name })
	text(row, { Position = UDim2.fromOffset(10, 28), Size = UDim2.new(1, -140, 0, 36), TextSize = 13, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Text = item.description })
	local status = text(row, { Position = UDim2.new(1, -124, 0, 44), Size = UDim2.fromOffset(114, 18), TextSize = 12, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Center })
	local button = Instance.new("TextButton")
	button.Position = UDim2.new(1, -124, 0, 8)
	button.Size = UDim2.fromOffset(114, 32)
	button.BackgroundColor3 = Color3.fromRGB(60, 90, 50)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Code
	button.TextSize = 15
	button.TextColor3 = PALE
	button.Parent = row
	juice(button)
	button.Activated:Connect(function()
		Audio.ui("UI_CLICK")
		BuyItem:FireServer(item.id)
	end)
	return { item = item, frame = row, button = button, status = status }
end

for _, item in ShopItems do
	table.insert(rows, rowFor(item))
end

-- Show the rows this counter sells, top to bottom.
local function layout()
	title.Text = if mode == "lift" then "LIFT ARMOURY" else "SUPPLIES"
	local shown = 0
	for _, r in rows do
		local on = (r.item.where or "safehouse") == mode
		r.frame.Visible = on
		if on then
			r.frame.Position = UDim2.fromOffset(12, 46 + shown * 78)
			shown += 1
		end
	end
	panel.Size = UDim2.fromOffset(460, 96 + math.max(shown, 1) * 78)
end

local function refresh()
	cashText.Text = `CASH  ${player:GetAttribute("Cash") or 0}`
	for _, r in rows do
		local item = r.item
		if item.kind == "melee" then
			local holding = player:GetAttribute("Melee") == item.id
			local spec = item.melee :: ShopItems.Melee
			local uses = (player:GetAttribute("MeleeUses") or 0) :: number
			local full = holding and uses >= spec.uses
			r.button.Text = if full then "In hand" else `Buy  ${item.price[1]}`
			r.button.BackgroundColor3 = if full then Color3.fromRGB(45, 42, 34) else Color3.fromRGB(60, 90, 50)
			r.status.Text = if holding then `in hand: {uses} hits` else "one at a time"
		elseif item.kind == "permanent" then
			local level = (player:GetAttribute(`Own_{item.id}`) or 0) :: number
			if level >= #item.price then
				r.button.Text = "Owned"
				r.button.AutoButtonColor = false
				r.button.BackgroundColor3 = Color3.fromRGB(45, 42, 34)
				r.status.Text = if #item.price > 1 then `level {level}/{#item.price}` else ""
			else
				r.button.Text = `Buy  ${item.price[level + 1]}`
				r.button.BackgroundColor3 = Color3.fromRGB(60, 90, 50)
				r.status.Text = if #item.price > 1 then `level {level}/{#item.price}` else ""
			end
		else
			local have = player:GetAttribute(`Run_{item.id}`) == true
			r.button.Text = if have then "Packed" else `Buy  ${item.price[1]}`
			r.button.BackgroundColor3 = if have then Color3.fromRGB(45, 42, 34) else Color3.fromRGB(60, 90, 50)
			r.status.Text = "next run only"
		end
	end
end

local lastCash = (player:GetAttribute("Cash") or 0) :: number
player.AttributeChanged:Connect(function(name)
	if name == "Cash" then
		local cash = (player:GetAttribute("Cash") or 0) :: number
		if gui.Enabled and cash < lastCash then
			Audio.ui("PURCHASE") -- the server took the money: it went through
		end
		lastCash = cash
	end
	if gui.Enabled then
		refresh()
	end
end)

OpenShop.OnClientEvent:Connect(function(which: string?)
	mode = if which == "lift" then "lift" else "safehouse"
	layout()
	refresh()
	if not gui.Enabled then
		Audio.ui("UI_OPEN")
		openPanel()
	end
end)

-- Flashlight: F (or gamepad D-pad up, or the on-screen button once owned).
ContextActionService:BindAction("Flashlight", function(_, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin then
		if (player:GetAttribute("Own_flashlight") or 0) > 0 then
			Audio.play("FLASHLIGHT", { volume = 0.6, jitter = 0.05 })
		end
		ToggleFlashlight:FireServer()
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.F, Enum.KeyCode.DPadUp)
ContextActionService:SetTitle("Flashlight", "Light")
ContextActionService:SetPosition("Flashlight", UDim2.new(1, -230, 1, -150))
