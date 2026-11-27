--!strict
-- Animates the entities on this device. The server only moves each
-- entity's root and says what it's doing (attributes Gait, State,
-- AttackAt); the body is animated here, which is smooth and costs the
-- server nothing.
--
-- If Jason has made animations in the Animation Editor and put their IDs
-- in Config.ANIMATIONS, those play. Otherwise a procedural animation
-- drives the rig's Motor6D joints:
--   The Tenant: a slow, long-limbed walk; a loping run with arms
--               reaching when it hunts; a head that twitches when it
--               stops to listen or spots you; a lunge when it takes you.
--   Lampjaw:    a neck that sways under the light and a chattering jaw;
--               a bite when it takes you. It's only visible in the red
--               flashes of its light: glimpsed, never seen clearly.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer

type Rig = {
	model: Model,
	kind: string,
	motors: { [string]: Motor6D },
	tracks: { [string]: AnimationTrack }?,
	playing: string?,
	phase: number,
	last: Vector3,
	speed: number,
	attackSeen: number,
	panel: BasePart?,
}
local rigs: { [Model]: Rig } = {}

local function animatorOf(model: Model): Animator?
	local holder = model:FindFirstChildOfClass("AnimationController") or model:FindFirstChildOfClass("Humanoid")
	return holder and holder:FindFirstChildOfClass("Animator")
end

local function loadTracks(model: Model, kind: string): { [string]: AnimationTrack }?
	local ids = (Config.ANIMATIONS :: any)[kind]
	if not ids then
		return nil
	end
	local animator = animatorOf(model)
	if not animator then
		return nil
	end
	local tracks: { [string]: AnimationTrack } = {}
	local any = false
	for key, id in ids do
		if id ~= "" then
			local a = Instance.new("Animation")
			a.AnimationId = if string.match(id, "^%d+$") then `rbxassetid://{id}` else id
			local ok, track = pcall(function()
				return animator:LoadAnimation(a)
			end)
			if ok and track then
				track.Looped = key ~= "attack"
				track.Priority = if key == "attack" then Enum.AnimationPriority.Action else Enum.AnimationPriority.Movement
				tracks[key] = track
				any = true
			end
		end
	end
	return if any then tracks else nil
end

local function track(model: Model)
	if rigs[model] then
		return
	end
	local kind = model:GetAttribute("Entity")
	if typeof(kind) ~= "string" then
		return
	end
	local motors: { [string]: Motor6D } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") then
			motors[d.Name] = d
		end
	end
	rigs[model] = {
		model = model,
		kind = kind,
		motors = motors,
		tracks = loadTracks(model, kind),
		playing = nil,
		phase = 0,
		last = model:GetPivot().Position,
		speed = 0,
		attackSeen = (model:GetAttribute("AttackAt") or 0) :: number,
		panel = nil,
	}
end

CollectionService:GetInstanceAddedSignal("SHIFT_Entity"):Connect(function(inst)
	if inst:IsA("Model") then
		track(inst)
	end
end)
CollectionService:GetInstanceRemovedSignal("SHIFT_Entity"):Connect(function(inst)
	rigs[inst :: any] = nil
end)
for _, inst in CollectionService:GetTagged("SHIFT_Entity") do
	if inst:IsA("Model") then
		track(inst)
	end
end

local function set(r: Rig, name: string, cf: CFrame)
	local m = r.motors[name]
	if m then
		m.Transform = cf
	end
end

local function attacking(r: Rig): number
	-- 0..1 through the attack, or -1 when not attacking.
	local at = (r.model:GetAttribute("AttackAt") or 0) :: number
	local t = workspace:GetServerTimeNow() - at
	if t >= 0 and t < 0.7 then
		return t / 0.7
	end
	return -1
end

-- Animation Editor tracks, when Jason has made them.
local function playTracks(r: Rig)
	local tracks = r.tracks :: { [string]: AnimationTrack }
	local gait = r.model:GetAttribute("Gait") or "idle"
	local wanted = if tracks[gait :: string] then gait :: string elseif tracks.walk and gait ~= "idle" then "walk" else "idle"
	if r.playing ~= wanted then
		if r.playing and tracks[r.playing] then
			tracks[r.playing]:Stop(0.25)
		end
		if tracks[wanted] then
			tracks[wanted]:Play(0.25)
		end
		r.playing = wanted
	end
	local current = tracks[wanted]
	if current and wanted ~= "idle" then
		current:AdjustSpeed(math.clamp(r.speed / (if wanted == "run" then 20 else 8), 0.4, 2))
	end
	local at = (r.model:GetAttribute("AttackAt") or 0) :: number
	if at ~= r.attackSeen then
		r.attackSeen = at
		if tracks.attack then
			tracks.attack:Play(0.05)
		end
	end
end

local function tenantPose(r: Rig, t: number, dt: number)
	local gait = r.model:GetAttribute("Gait")
	local st = r.model:GetAttribute("State")
	local running = gait == "run"
	local amp = if gait == "idle" then 0 else math.clamp(r.speed / 7, 0, 1) * (if running then 1.35 else 1)
	r.phase += dt * (r.speed / 4.4) * math.pi
	local s, c = math.sin(r.phase), math.cos(r.phase)
	local breathe = math.sin(t * 1.3) * 0.025

	-- Legs: long, slow strides; knees fold on the back swing.
	set(r, "LeftHip", CFrame.Angles(s * 0.5 * amp, 0, 0))
	set(r, "RightHip", CFrame.Angles(-s * 0.5 * amp, 0, 0))
	set(r, "LeftKnee", CFrame.Angles(-math.max(0, -c) * 0.8 * amp, 0, 0))
	set(r, "RightKnee", CFrame.Angles(-math.max(0, c) * 0.8 * amp, 0, 0))
	set(r, "LeftAnkle", CFrame.Angles(math.max(0, c) * 0.3 * amp, 0, 0))
	set(r, "RightAnkle", CFrame.Angles(math.max(0, -c) * 0.3 * amp, 0, 0))
	set(r, "Root", CFrame.new(0, math.abs(s) * 0.18 * amp - 0.05 * amp, 0))

	-- Torso: leans in when it runs, rises and falls as it breathes.
	local lean = if running then -0.28 else 0
	set(r, "Waist", CFrame.Angles(lean + breathe, s * 0.1 * amp, 0))

	-- Arms: hang and swing loosely; when it hunts they reach forward.
	local reach = if running then -0.55 else 0
	local att = attacking(r)
	if att >= 0 then
		local lunge = math.sin(att * math.pi)
		reach = -1.7 * lunge
		set(r, "Waist", CFrame.Angles(-0.5 * lunge, 0, 0))
	end
	local lag = math.sin(r.phase - 0.6)
	set(r, "LeftShoulder", CFrame.Angles(reach - lag * 0.35 * amp + breathe, 0, -0.04))
	set(r, "RightShoulder", CFrame.Angles(reach + lag * 0.35 * amp + breathe, 0, 0.04))
	set(r, "LeftElbow", CFrame.Angles(-0.12 - math.max(0, lag) * 0.3 * amp, 0, 0))
	set(r, "RightElbow", CFrame.Angles(-0.12 - math.max(0, -lag) * 0.3 * amp, 0, 0))

	-- Head: slow, searching turns; a nervous twitch while it listens or
	-- has just spotted someone.
	local twitch = st == "notice" or (st == "investigate" and gait == "idle")
	local jx, jy, jz = 0, 0, 0
	if twitch and math.random() < 0.25 then
		jx, jy, jz = (math.random() - 0.5) * 0.35, (math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.7
	end
	set(r, "Neck", CFrame.Angles(math.sin(t * 0.37) * 0.08 + jx, math.sin(t * 0.23) * 0.45 + jy, math.sin(t * 0.61) * 0.1 + jz))
end

local function lampjawPose(r: Rig, t: number)
	local att = attacking(r)
	local sway = math.sin(t * 0.9)
	if att >= 0 then
		local bite = math.sin(att * math.pi)
		set(r, "Drop", CFrame.new(0, -1.3 * bite, -0.6 * bite) * CFrame.Angles(-0.4 * bite, 0, 0))
		set(r, "Jaw", CFrame.Angles(-1.0 * bite, 0, 0))
		set(r, "Skull", CFrame.Angles(0.3 * bite, 0, 0))
		return
	end
	set(r, "Drop", CFrame.Angles(sway * 0.12, math.sin(t * 0.5) * 0.6, math.sin(t * 0.7) * 0.1))
	set(r, "Skull", CFrame.Angles(math.sin(t * 1.7) * 0.15, 0, 0))
	-- Chattering: fast, uneven snaps.
	local chatter = math.abs(math.sin(t * 11)) * (0.5 + 0.5 * math.sin(t * 2.3))
	set(r, "Jaw", CFrame.Angles(-0.1 - chatter * 0.35, 0, 0))
end

-- Lampjaw shows only while its light is in a red flash.
local function lampjawPanel(r: Rig): BasePart?
	local key = r.model:GetAttribute("Cell")
	if r.panel and r.panel.Parent and r.panel:GetAttribute("Cell") == key then
		return r.panel
	end
	r.panel = nil
	for _, inst in CollectionService:GetTagged("FlickerLight") do
		if inst:IsA("BasePart") and inst:GetAttribute("Cell") == key and inst:GetAttribute("Crew") == r.model:GetAttribute("Crew") then
			r.panel = inst
			break
		end
	end
	return r.panel
end

local function setVisible(model: Model, visible: boolean)
	local v = if visible then 0 else 1
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.LocalTransparencyModifier = v
		end
	end
end

RunService.Stepped:Connect(function(_, dt)
	local t = os.clock()
	local cam = workspace.CurrentCamera
	for model, r in rigs do
		if not model.Parent then
			rigs[model] = nil
			continue
		end
		-- Far away (another crew's level): don't bother.
		local pos = model:GetPivot().Position
		if cam and (cam.CFrame.Position - pos).Magnitude > 260 then
			r.last = pos
			continue
		end
		local moved = Vector3.new(pos.X - r.last.X, 0, pos.Z - r.last.Z).Magnitude
		r.last = pos
		local instant = if dt > 0 then moved / dt else 0
		if moved > 8 then
			instant = 0 -- it appeared somewhere new
		end
		r.speed += (instant - r.speed) * math.min(1, dt * 6)

		if r.tracks then
			playTracks(r)
		elseif r.kind == "Tenant" then
			tenantPose(r, t, dt)
		elseif r.kind == "Lampjaw" then
			lampjawPose(r, t)
		end
		if r.kind == "Lampjaw" then
			local panel = lampjawPanel(r)
			setVisible(model, attacking(r) >= 0 or (panel ~= nil and panel.Material == Enum.Material.Neon and panel.Color.R > panel.Color.G * 1.5))
		end
	end
end)
