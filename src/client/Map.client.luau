--!strict
-- The crew's shared map. Press M (or the Map button) to open it.
-- Shows every corridor anyone on the server has seen, the exit lift, and
-- where everyone is. Parts seen before the last Shift are faded: the maze
-- may have rebuilt there since.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MapSync = Remotes:WaitForChild("MapSync") :: RemoteEvent
local MapRequest = Remotes:WaitForChild("MapRequest") :: RemoteEvent

local player = Players.LocalPlayer
local CELL = 20 -- studs per cell (LevelBuilder.CELL)
local MAP_PX = 340

local AMBER = Color3.fromRGB(255, 196, 110)
local PALE = Color3.fromRGB(235, 228, 200)
local FLOOR = Color3.fromRGB(70, 62, 40)
local STALE = Color3.fromRGB(110, 104, 90)

local gui = Instance.new("ScreenGui")
gui.Name = "CrewMap"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(MAP_PX + 24, MAP_PX + 64)
panel.BackgroundColor3 = Color3.fromRGB(18, 16, 12)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Parent = gui

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 6)
title.Size = UDim2.new(1, -24, 0, 22)
title.Font = Enum.Font.Code
title.TextSize = 18
title.TextColor3 = AMBER
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "CREW MAP"
title.Parent = panel

local note = title:Clone()
note.Position = UDim2.new(0, 12, 1, -28)
note.TextSize = 13
note.TextColor3 = STALE
note.Text = "faded = seen before the last Shift"
note.Parent = panel

local grid = Instance.new("Frame")
grid.BackgroundTransparency = 1
grid.Position = UDim2.fromOffset(12, 34)
grid.Size = UDim2.fromOffset(MAP_PX, MAP_PX)
grid.ClipsDescendants = true
grid.Parent = panel

local width, depth = 14, 14
local px = MAP_PX / 14
local known: { [number]: { mask: number, shift: number } } = {}
local cellFrames: { [number]: Frame } = {}

local function box(parent: Instance, x: number, y: number, w: number, h: number, colour: Color3, transparency: number): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = colour
	f.BackgroundTransparency = transparency
	f.Parent = parent
	return f
end

local function drawCell(key: number)
	local entry = known[key]
	local old = cellFrames[key]
	if old then
		old:Destroy()
	end
	if not entry then
		return
	end
	local stale = entry.shift < ((workspace:GetAttribute("ShiftCount") or 0) :: number)
	local x, z = key // 1000, key % 1000
	local f = box(grid, (x - 1) * px, (z - 1) * px, px, px, if stale then STALE else FLOOR, if stale then 0.75 else 0.2)
	local wallColour = if stale then STALE else PALE
	local t = math.max(2, math.floor(px / 8))
	local m = entry.mask
	if m % 2 == 1 then box(f, px - t, 0, t, px, wallColour, 0) end -- east
	if (m // 2) % 2 == 1 then box(f, 0, px - t, px, t, wallColour, 0) end -- south
	if (m // 4) % 2 == 1 then box(f, 0, 0, t, px, wallColour, 0) end -- west
	if (m // 8) % 2 == 1 then box(f, 0, 0, px, t, wallColour, 0) end -- north
	cellFrames[key] = f
end

local function redrawAll()
	for key in cellFrames do
		drawCell(key)
	end
end

MapSync.OnClientEvent:Connect(function(kind: string, a: any, b: any)
	if kind == "reset" then
		width, depth = a, b
		px = math.floor(MAP_PX / math.max(width, depth))
		for _, f in cellFrames do
			f:Destroy()
		end
		table.clear(cellFrames)
		table.clear(known)
	elseif kind == "cells" then
		for _, e in a do
			known[e.key] = { mask = e.mask, shift = e.shift }
			drawCell(e.key)
		end
	end
end)
MapRequest:FireServer()
-- Fade everything seen so far when a Shift happens.
workspace:GetAttributeChangedSignal("ShiftCount"):Connect(redrawAll)

-- Markers: the lift and every player.
local liftMarker = box(grid, 0, 0, 10, 10, AMBER, 0)
liftMarker.AnchorPoint = Vector2.new(0.5, 0.5)
liftMarker.ZIndex = 3
local dots: { [Player]: Frame } = {}

local function toMap(pos: Vector3): (number, number)
	return pos.X / CELL * px, pos.Z / CELL * px
end

RunService.RenderStepped:Connect(function()
	if not gui.Enabled then
		return
	end
	local lift = workspace:GetAttribute("LiftPosition")
	liftMarker.Visible = typeof(lift) == "Vector3"
	if typeof(lift) == "Vector3" then
		local x, y = toMap(lift)
		liftMarker.Position = UDim2.fromOffset(x, y)
	end
	for _, p in Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local dot = dots[p]
		if not dot then
			dot = box(grid, 0, 0, 8, 8, if p == player then AMBER else PALE, 0)
			dot.AnchorPoint = Vector2.new(0.5, 0.5)
			dot.ZIndex = 4
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = dot
			dots[p] = dot
		end
		dot.Visible = root ~= nil
		if root then
			local x, y = toMap(root.Position)
			dot.Position = UDim2.fromOffset(x, y)
		end
	end
	for p, dot in dots do
		if not p.Parent then
			dot:Destroy()
			dots[p] = nil
		end
	end
end)

ContextActionService:BindAction("ToggleMap", function(_, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin then
		gui.Enabled = not gui.Enabled
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.M, Enum.KeyCode.ButtonY)
ContextActionService:SetTitle("ToggleMap", "Map")
ContextActionService:SetPosition("ToggleMap", UDim2.new(1, -90, 1, -150))
