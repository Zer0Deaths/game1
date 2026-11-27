--!strict
-- Game feel on this device: particles and flashes for the things that
-- happen (all client-side; the server only says where).
--   pickup:  a puff of dust and a glint where the loot was
--   drop:    dust kicked up off the floor
--   death:   a burst of dark dust, a red Highlight flash on the body,
--            and for you a red flash over the screen and a jolt
--   deposit: amber sparks in the lift as loot is banked
-- Big moments shake the camera (CameraFx; never moves your aim):
-- the blackout's thunk and the lift dropping.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local CameraFx = require(script.Parent:WaitForChild("CameraFx"))

local player = Players.LocalPlayer
local Fx = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Fx") :: RemoteEvent

local DUST = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

-- One burst of particles at a point, then cleaned up.
local function burst(position: Vector3, props: { [string]: any }, count: number)
	local a = Instance.new("Attachment")
	a.WorldPosition = position
	a.Parent = workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.Texture = DUST
	e.LightInfluence = 1
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 4
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = a
	e:Emit(count)
	Debris:AddItem(a, 4)
end

local function dust(position: Vector3, colour: Color3, size: number, count: number)
	burst(position, {
		Color = ColorSequence.new(colour),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.4), NumberSequenceKeypoint.new(1, size) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }),
		Acceleration = Vector3.new(0, 1.5, 0),
		RotSpeed = NumberRange.new(-40, 40),
		Rotation = NumberRange.new(0, 360),
	}, count)
end

local function glint(position: Vector3, colour: Color3, count: number)
	burst(position, {
		Texture = SPARK,
		Color = ColorSequence.new(colour),
		LightEmission = 1,
		LightInfluence = 0,
		Lifetime = NumberRange.new(0.25, 0.6),
		Speed = NumberRange.new(3, 9),
		Drag = 6,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new(0),
	}, count)
end

-- A brief red outline on a body (others see you fall).
local function flash(character: Model)
	local h = Instance.new("Highlight")
	h.FillColor = Color3.fromRGB(200, 30, 20)
	h.OutlineColor = Color3.fromRGB(255, 80, 60)
	h.FillTransparency = 0.35
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = character
	TweenService:Create(h, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	Debris:AddItem(h, 1)
end

-- Your own screen going red for a moment.
local gui = Instance.new("ScreenGui")
gui.Name = "HurtFlash"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local red = Instance.new("Frame")
red.Size = UDim2.fromScale(1, 1)
red.BackgroundColor3 = Color3.fromRGB(120, 10, 6)
red.BackgroundTransparency = 1
red.BorderSizePixel = 0
red.Parent = gui
local function screenFlash()
	red.BackgroundTransparency = 0.35
	TweenService:Create(red, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
end

Fx.OnClientEvent:Connect(function(kind: string, position: Vector3)
	if typeof(position) ~= "Vector3" then
		return
	end
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - position).Magnitude > 200 then
		return -- another crew's level
	end
	if kind == "pickup" then
		dust(position, Color3.fromRGB(170, 160, 130), 1.2, 6)
		glint(position + Vector3.new(0, 0.5, 0), Color3.fromRGB(255, 220, 150), 5)
	elseif kind == "drop" then
		dust(position - Vector3.new(0, 0.5, 0), Color3.fromRGB(150, 140, 110), 1.6, 10)
	elseif kind == "death" then
		dust(position, Color3.fromRGB(20, 18, 16), 3, 26)
	elseif kind == "melee_hit" then
		dust(position, Color3.fromRGB(30, 28, 26), 1.4, 12)
	elseif kind == "melee_glass" then
		glint(position, Color3.fromRGB(230, 240, 255), 10)
		dust(position, Color3.fromRGB(210, 214, 220), 1.2, 14)
	end
end)

-- Deaths: a flash on every body that falls; your own adds the red screen.
local function watch(p: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		flash(character)
		if p == player then
			screenFlash()
			CameraFx.shake(0.3, 0.6)
			CameraFx.kick(10)
		end
	end)
end
local function onPlayer(p: Player)
	p.CharacterAdded:Connect(function(c)
		watch(p, c)
	end)
	if p.Character then
		task.spawn(watch, p, p.Character)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	onPlayer(p)
end

-- Loot banked: sparks in the lift.
local lastBanked = (workspace:GetAttribute("CrewBanked") or 0) :: number
workspace:GetAttributeChangedSignal("CrewBanked"):Connect(function()
	local banked = (workspace:GetAttribute("CrewBanked") or 0) :: number
	local lift = workspace:GetAttribute("LiftPosition")
	if banked > lastBanked and typeof(lift) == "Vector3" then
		glint(lift + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 190, 90), 18)
	end
	lastBanked = banked
end)

-- Big moments.
workspace:GetAttributeChangedSignal("Shifting"):Connect(function()
	if workspace:GetAttribute("Shifting") then
		CameraFx.shake(0.12, 0.45) -- every light dies with a thunk
	end
end)
workspace:GetAttributeChangedSignal("CrewRunState"):Connect(function()
	local st = workspace:GetAttribute("CrewRunState")
	if st == "descending" then
		CameraFx.shake(0.08, 1.5) -- the cage lurches as the brakes let go
	elseif st == "playing" then
		CameraFx.shake(0.14, 0.4) -- and bumps to a stop
	end
end)
