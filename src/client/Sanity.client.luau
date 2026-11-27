--!strict
-- Sanity (0-100), on your own device. It drains in the dark and near the
-- entities, and comes back in the light, near your crew, and in the
-- safehouse. As it falls:
--   * the edges of your view close in (vignette) and colour drains out
--   * the heartbeat and whispers fade in (Cues, Ambience read "Sanity")
--   * the view leans slightly (CameraFx)
--   * below 35 you start seeing the Tenant where it isn't: a tall dark
--     figure at the end of a corridor that is gone when you look straight
--     at it, and its breathing behind you that isn't there
-- Purely atmosphere: nothing on the server depends on it, so it can't be
-- abused. The value is a local attribute on your Player.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Audio = require(script.Parent:WaitForChild("Audio"))
local CameraFx = require(script.Parent:WaitForChild("CameraFx"))

local player = Players.LocalPlayer

-- Tuning: points per second.
local DRAIN_DARK = 1.3 -- standing where no working tube reaches
local DRAIN_BLACKOUT = 2.5 -- during the Shift's blackout
local DRAIN_ENTITY = 5 -- right next to the Tenant (less further away)
local DRAIN_LAMPJAW = 2 -- under or near Lampjaw's light
local REGEN_LIGHT = 0.7 -- in the light, nothing near
local REGEN_CREW = 0.6 -- extra with a crewmate close by
local REGEN_SAFEHOUSE = 10
local LIT_RADIUS = 15 -- studs from a working tube that count as lit

local sanity = 100
player:SetAttribute("Sanity", sanity)

local function myCrew(inst: Instance): boolean
	return inst:GetAttribute("Crew") == player:GetAttribute("Crew")
end

-- SCREEN EFFECTS ------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "Sanity"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = -1 -- under the HUD
gui.Parent = player:WaitForChild("PlayerGui")

-- Vignette: four soft dark edges that grow inwards.
local edges: { Frame } = {}
local function edge(anchor: Vector2, pos: UDim2, rotation: number)
	local f = Instance.new("Frame")
	f.AnchorPoint = anchor
	f.Position = pos
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 0
	local g = Instance.new("UIGradient")
	g.Rotation = rotation
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = f
	f.Parent = gui
	table.insert(edges, f)
end
edge(Vector2.new(0, 0), UDim2.fromScale(0, 0), 90) -- top, dark at the top
edge(Vector2.new(0, 1), UDim2.fromScale(0, 1), -90) -- bottom
edge(Vector2.new(0, 0), UDim2.fromScale(0, 0), 0) -- left
edge(Vector2.new(1, 0), UDim2.fromScale(1, 0), 180) -- right

local function setVignette(v: number)
	local depth = 0.05 + 0.3 * v -- how far in each edge reaches
	edges[1].Size = UDim2.fromScale(1, depth)
	edges[2].Size = UDim2.fromScale(1, depth)
	edges[3].Size = UDim2.fromScale(depth * 0.7, 1)
	edges[4].Size = UDim2.fromScale(depth * 0.7, 1)
	for _, f in edges do
		f.BackgroundTransparency = 1 - math.clamp(v * 1.1, 0, 0.92)
	end
end

-- Colour draining out (only on this screen).
local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "SanityGrade"
local function parentGrade()
	grade.Parent = workspace.CurrentCamera
end
parentGrade()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(parentGrade)

-- Meter: a thin bar right of the stamina bar, only in the level.
local back = Instance.new("Frame")
back.AnchorPoint = Vector2.new(0, 1)
back.Position = UDim2.new(0, 270, 1, -20)
back.Size = UDim2.fromOffset(150, 6)
back.BackgroundColor3 = Color3.fromRGB(20, 18, 12)
back.BackgroundTransparency = 0.3
back.BorderSizePixel = 0
back.Visible = false
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "SanityMeter"
hudGui.ResetOnSpawn = false
hudGui.Parent = player:WaitForChild("PlayerGui")
back.Parent = hudGui
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(150, 190, 178)
fill.BorderSizePixel = 0
fill.Parent = back
local tag = Instance.new("TextLabel")
tag.BackgroundTransparency = 1
tag.AnchorPoint = Vector2.new(0, 1)
tag.Position = UDim2.new(0, 0, 0, -2)
tag.Size = UDim2.fromOffset(150, 14)
tag.Font = Enum.Font.Code
tag.TextSize = 12
tag.TextXAlignment = Enum.TextXAlignment.Left
tag.TextColor3 = Color3.fromRGB(150, 190, 178)
tag.TextStrokeTransparency = 0.6
tag.Text = "SANITY"
tag.Parent = back

-- WHAT DRAINS IT ------------------------------------------------------------

local lights: { [BasePart]: boolean } = {}
local function addLight(inst: Instance)
	if inst:IsA("BasePart") then
		lights[inst] = true
	end
end
CollectionService:GetInstanceAddedSignal("LightFitting"):Connect(addLight)
CollectionService:GetInstanceRemovedSignal("LightFitting"):Connect(function(inst)
	lights[inst :: any] = nil
end)
for _, inst in CollectionService:GetTagged("LightFitting") do
	addLight(inst)
end

local function isLit(pos: Vector3): boolean
	if workspace:GetAttribute("Shifting") then
		return false
	end
	local r2 = LIT_RADIUS * LIT_RADIUS
	for panel in lights do
		if panel.Parent and panel:GetAttribute("LightState") ~= "dead" and myCrew(panel) then
			local d = panel.Position - pos
			if d.X * d.X + d.Z * d.Z <= r2 then
				return true
			end
		end
	end
	return false
end

local function inLevel(root: BasePart): boolean
	return root.Position.X >= 0 and workspace:GetAttribute("RunState") == "playing"
end

local function nearestTenant(pos: Vector3): (number, Model?)
	local best, which = math.huge, nil
	for _, inst in CollectionService:GetTagged("SHIFT_Tenant") do
		if inst:IsA("Model") and myCrew(inst) and inst:IsDescendantOf(workspace) then
			local d = (inst:GetPivot().Position - pos).Magnitude
			if d < best then
				best, which = d, inst
			end
		end
	end
	return best, which
end

local function lampjawDistance(pos: Vector3): number
	local key = (workspace:GetAttribute("LampjawCell") or 0) :: number
	if key == 0 then
		return math.huge
	end
	local origin = workspace:GetAttribute("LevelOrigin")
	if typeof(origin) ~= "Vector3" then
		return math.huge
	end
	local x, z = key // 1000, key % 1000
	local centre = origin + Vector3.new((x - 0.5) * 20, 0, (z - 0.5) * 20)
	return (Vector3.new(centre.X, pos.Y, centre.Z) - pos).Magnitude
end

local function crewmateNear(pos: Vector3): boolean
	for _, p in Players:GetPlayers() do
		if p ~= player and p:GetAttribute("Crew") == player:GetAttribute("Crew") then
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if r and h and h.Health > 0 and (r.Position - pos).Magnitude < 25 then
				return true
			end
		end
	end
	return false
end

-- HALLUCINATIONS --------------------------------------------------------------

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- A tall, thin, near-black shape. Only ever on this screen.
local function figure(at: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Glimpse"
	local BLACK = Color3.fromRGB(10, 10, 11)
	local function piece(size: Vector3, offset: CFrame, ball: boolean?)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = size
		p.Color = BLACK
		p.Material = Enum.Material.Rubber
		p.Shape = if ball then Enum.PartType.Ball else Enum.PartType.Block
		p.CFrame = at * offset
		p.Parent = m
	end
	piece(Vector3.new(1.3, 4.2, 0.8), CFrame.new(0, 6.2, 0)) -- torso
	piece(Vector3.new(1.1, 1.1, 1.1), CFrame.new(0, 8.9, -0.3), true) -- head, pushed forward
	for _, side in { -1, 1 } do
		piece(Vector3.new(0.4, 4.3, 0.4), CFrame.new(side * 0.4, 2.15, 0)) -- legs
		piece(Vector3.new(0.3, 5.2, 0.3), CFrame.new(side * 0.95, 5.2, -0.1) * CFrame.Angles(0, 0, side * 0.06)) -- arms past the knees
	end
	return m
end

local nextGlimpse = os.clock() + 20
local function tryGlimpse(root: BasePart)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local exclude: { Instance } = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = exclude
	-- Look a little off to the side of where you're facing: the edge of
	-- your vision, at the end of the corridor.
	local look = cam.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z).Unit
	local side = (math.random() < 0.5) and -1 or 1
	local dir = (CFrame.Angles(0, side * math.rad(12 + math.random() * 14), 0) * flat).Unit
	local eye = root.Position + Vector3.new(0, 1.5, 0)
	local hit = workspace:Raycast(eye, dir * 120, rayParams)
	local dist = if hit then hit.Distance - 3 else 90
	if dist < 28 then
		return -- too close: a glimpse has to be far off
	end
	local spot = eye + dir * dist
	local floor = workspace:Raycast(spot, Vector3.new(0, -12, 0), rayParams)
	if not floor then
		return
	end
	local at = CFrame.lookAt(floor.Position, Vector3.new(eye.X, floor.Position.Y, eye.Z))
	local m = figure(at)
	m.Parent = workspace.CurrentCamera -- local only
	local shown = os.clock()
	local life = 0.35 + math.random() * 0.45
	task.spawn(function()
		while m.Parent and os.clock() - shown < life do
			-- Look straight at it and it's gone.
			local to = (at.Position + Vector3.new(0, 6, 0) - cam.CFrame.Position).Unit
			if cam.CFrame.LookVector:Dot(to) > 0.985 then
				break
			end
			task.wait()
		end
		m:Destroy()
		if math.random() < 0.6 then
			Audio.sting("STING_GLIMPSE", 0.45, 8)
		end
	end)
end

local function phantomBreath(root: BasePart)
	-- Its breathing, right behind you. Nothing's there.
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local behind = root.Position - Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit * 18
	Audio.at("TENANT_CUE", behind + Vector3.new(0, 5, 0), { group = "Entities", volume = 0.6, maxDistance = 60, fallback = "HUM", speed = 1 })
end

-- MAIN LOOP ---------------------------------------------------------------------

local shown = 100
local last = os.clock()
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local dt = now - last
	if dt < 0.2 then
		return
	end
	last = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local active = root ~= nil and humanoid ~= nil and humanoid.Health > 0 and inLevel(root :: BasePart)
	if not active or not root then
		sanity = math.min(100, sanity + REGEN_SAFEHOUSE * dt)
	else
		local pos = root.Position
		local delta = 0
		local lit = isLit(pos)
		local flashlight = player:GetAttribute("FlashlightOn") == true
		if workspace:GetAttribute("Shifting") then
			delta -= DRAIN_BLACKOUT
		elseif not lit then
			delta -= DRAIN_DARK * (if flashlight then 0.4 else 1)
		end
		local d = nearestTenant(pos)
		if d < 55 then
			delta -= DRAIN_ENTITY * (1 - d / 55)
		end
		if lampjawDistance(pos) < 30 then
			delta -= DRAIN_LAMPJAW
		end
		local crew = crewmateNear(pos)
		if delta < 0 and crew then
			delta *= 0.6 -- company helps
		elseif delta >= 0 and lit then
			delta += REGEN_LIGHT + (if crew then REGEN_CREW else 0)
		end
		sanity = math.clamp(sanity + delta * dt, 0, 100)

		-- Hallucinations once it's low.
		if sanity < 35 and now >= nextGlimpse then
			local gap = 14 + (sanity / 35) * 20 + math.random() * 10
			nextGlimpse = now + gap
			if math.random() < 0.7 then
				tryGlimpse(root)
			else
				phantomBreath(root)
			end
		end
	end
	player:SetAttribute("Sanity", math.floor(sanity * 10) / 10)

	-- Screen effects, eased.
	shown += (sanity - shown) * 0.35
	local v = math.clamp((70 - shown) / 70, 0, 1)
	setVignette(v)
	grade.Saturation = -0.6 * v
	grade.Contrast = 0.15 * v
	grade.Brightness = -0.05 * v
	back.Visible = active
	fill.Size = UDim2.fromScale(sanity / 100, 1)
	fill.BackgroundColor3 = if sanity < 30 then Color3.fromRGB(200, 110, 90) else Color3.fromRGB(150, 190, 178)
end)

-- A fresh start after dying.
player.CharacterAdded:Connect(function()
	sanity = 100
	shown = 100
end)

-- Losing a lot at once (a sudden scare) gives a little jolt.
local lastValue = sanity
task.spawn(function()
	while true do
		task.wait(0.5)
		if lastValue - sanity > 6 then
			CameraFx.shake(0.05, 0.3)
		end
		lastValue = sanity
	end
end)

