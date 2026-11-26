--!strict
-- The safehouse shop screen. Opens from the counter's prompt. Buying is
-- checked by the server (ShopService); this only shows what's on offer.
-- Also: F toggles your flashlight once you own one.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopItems = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopItems"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OpenShop = Remotes:WaitForChild("OpenShop") :: RemoteEvent
local BuyItem = Remotes:WaitForChild("BuyItem") :: RemoteEvent
local ToggleFlashlight = Remotes:WaitForChild("ToggleFlashlight") :: RemoteEvent

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
panel.Size = UDim2.fromOffset(460, 96 + #ShopItems * 78)
panel.BackgroundColor3 = Color3.fromRGB(18, 16, 12)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Parent = gui

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

text(panel, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -120, 0, 26), TextSize = 20, TextColor3 = AMBER, Text = "SUPPLIES" })
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
close.Activated:Connect(function()
	gui.Enabled = false
end)

type Row = { item: ShopItems.Item, button: TextButton, status: TextLabel }
local rows: { Row } = {}

for i, item in ShopItems do
	local y = 46 + (i - 1) * 78
	local row = Instance.new("Frame")
	row.Position = UDim2.fromOffset(12, y)
	row.Size = UDim2.new(1, -24, 0, 70)
	row.BackgroundColor3 = Color3.fromRGB(32, 29, 22)
	row.BorderSizePixel = 0
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
	button.Activated:Connect(function()
		BuyItem:FireServer(item.id)
	end)
	table.insert(rows, { item = item, button = button, status = status })
end

local function refresh()
	cashText.Text = `CASH  ${player:GetAttribute("Cash") or 0}`
	for _, r in rows do
		local item = r.item
		if item.kind == "permanent" then
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

player.AttributeChanged:Connect(function()
	if gui.Enabled then
		refresh()
	end
end)

OpenShop.OnClientEvent:Connect(function()
	refresh()
	gui.Enabled = true
end)

-- Flashlight: F (or gamepad D-pad up, or the on-screen button once owned).
ContextActionService:BindAction("Flashlight", function(_, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin then
		ToggleFlashlight:FireServer()
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.F, Enum.KeyCode.DPadUp)
ContextActionService:SetTitle("Flashlight", "Light")
ContextActionService:SetPosition("Flashlight", UDim2.new(1, -230, 1, -150))
