-- Lift compass: a needle at the top of the screen pointing toward the
-- exit lift. It is honest but nervous: the further away you are, the
-- more the needle wanders. When the Workspace attribute "Shifting" is
-- true (set by the Shift later), it spins out completely.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local AMBER = Color3.fromRGB(255, 196, 110)
local MAX_WOBBLE = 50 -- degrees of wander when far away
local FAR = 220 -- studs at which wobble is at its worst
local NEAR = 25 -- inside this, the needle is steady and glows

local gui = Instance.new("ScreenGui")
gui.Name = "Compass"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local dial = Instance.new("Frame")
dial.Name = "Dial"
dial.AnchorPoint = Vector2.new(0.5, 0)
dial.Position = UDim2.new(0.5, 0, 0, 60)
dial.Size = UDim2.fromOffset(64, 64)
dial.BackgroundColor3 = Color3.fromRGB(20, 18, 12)
dial.BackgroundTransparency = 0.35
dial.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = dial
local ring = Instance.new("UIStroke")
ring.Color = AMBER
ring.Thickness = 2
ring.Transparency = 0.3
ring.Parent = dial

-- The needle: a thin bar with its pivot in the middle of the dial.
local needle = Instance.new("Frame")
needle.Name = "Needle"
needle.AnchorPoint = Vector2.new(0.5, 0.5)
needle.Position = UDim2.fromScale(0.5, 0.5)
needle.Size = UDim2.fromOffset(6, 48)
needle.BackgroundTransparency = 1
needle.Parent = dial
local tip = Instance.new("Frame")
tip.Name = "Tip"
tip.AnchorPoint = Vector2.new(0.5, 0)
tip.Position = UDim2.fromScale(0.5, 0)
tip.Size = UDim2.new(1, 0, 0.5, 0)
tip.BackgroundColor3 = AMBER
tip.BorderSizePixel = 0
tip.Parent = needle
local tail = Instance.new("Frame")
tail.Name = "Tail"
tail.AnchorPoint = Vector2.new(0.5, 1)
tail.Position = UDim2.fromScale(0.5, 1)
tail.Size = UDim2.new(0.6, 0, 0.5, 0)
tail.BackgroundColor3 = Color3.fromRGB(110, 100, 80)
tail.BorderSizePixel = 0
tail.Parent = needle

local caption = Instance.new("TextLabel")
caption.BackgroundTransparency = 1
caption.AnchorPoint = Vector2.new(0.5, 0)
caption.Position = UDim2.new(0.5, 0, 1, 2)
caption.Size = UDim2.fromOffset(80, 16)
caption.Font = Enum.Font.Code
caption.TextSize = 13
caption.TextColor3 = AMBER
caption.Text = "LIFT"
caption.Parent = dial

-- Heading of a flat direction, in degrees clockwise from "forward" (-Z).
local function heading(v: Vector3): number
	return math.deg(math.atan2(v.X, -v.Z))
end

local shown = 0 -- current needle angle, smoothed
local spin = 0

RunService.RenderStepped:Connect(function(dt)
	local lift = workspace:GetAttribute("LiftPosition")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local playing = workspace:GetAttribute("RunState") == "playing"
	-- Hidden in the safehouse (which sits at negative X; the level starts at 0).
	dial.Visible = typeof(lift) == "Vector3" and root ~= nil and playing and (root :: BasePart).Position.X >= 0
	if not dial.Visible then
		return
	end

	local t = os.clock()
	local target: number
	if workspace:GetAttribute("Shifting") then
		-- The Shift scrambles it: fast, erratic spinning.
		spin += dt * (540 + math.sin(t * 3) * 300)
		target = spin
	else
		local toLift = lift - root.Position
		local flat = Vector3.new(toLift.X, 0, toLift.Z)
		local look = camera.CFrame.LookVector
		local relative = heading(flat) - heading(Vector3.new(look.X, 0, look.Z))
		-- Wander grows with distance: two slow waves plus a little tremble.
		local far = math.clamp((flat.Magnitude - NEAR) / (FAR - NEAR), 0, 1)
		local wobble = (math.sin(t * 0.9) * 0.6 + math.sin(t * 2.3 + 1.7) * 0.4) * MAX_WOBBLE * far
		local tremble = (math.random() - 0.5) * 6 * far
		target = relative + wobble + tremble
		spin = target
		local near = flat.Magnitude <= NEAR
		ring.Transparency = if near then 0 else 0.3
		ring.Thickness = if near then 3 else 2
	end

	-- Smooth toward the target the short way round, like a real needle.
	local diff = ((target - shown + 180) % 360) - 180
	shown += diff * math.min(dt * 8, 1)
	needle.Rotation = shown
end)
