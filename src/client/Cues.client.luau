--!strict
-- Entity cues, the heartbeat, stingers and the sounds of the loop, on
-- this device.
--
-- ENTITIES are heard before they're seen. Each has ONE unique cue, a 3D
-- Sound on the entity with distance rolloff, so you can tell which way
-- it is and how close:
--   The Tenant:  TENANT_CUE, a wet clicking breath (+ heavy footfalls,
--                and a torn shriek when it spots someone)
--   Lampjaw:     LAMPJAW_CUE, an electrical crackle with chattering teeth,
--                from the light it is hiding in
-- HEARTBEAT fades in when an entity in your level is near, or your
-- Sanity is low. STINGERS hit on reveals: the first time you lay eyes on
-- the Tenant after it arrives, when it spots you, when Lampjaw takes a
-- light right by you, when you die, and when the crew is wiped.
-- The LOOP: loot banked in the lift, quota met, the countdown, the lift
-- going down and arriving.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local CameraFx = require(script.Parent:WaitForChild("CameraFx"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local CELL = 20

local function myCrew(inst: Instance): boolean
	return inst:GetAttribute("Crew") == player:GetAttribute("Crew")
end

local function myRoot(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- THE TENANT ---------------------------------------------------------------

type Watched = { model: Model, root: BasePart, cue: Sound, step: Sound?, revealed: boolean, last: Vector3, travelled: number }
local tenants: { [Model]: Watched } = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function visible(model: Model, from: Vector3): boolean
	local target = model:GetPivot().Position + Vector3.new(0, (Config.TENANT.height or 9) * 0.6, 0)
	local look = camera.CFrame.LookVector
	local to = target - from
	if to.Magnitude > 80 or look:Dot(to.Unit) < 0.55 then
		return false
	end
	local exclude: { Instance } = { model }
	if player.Character then
		table.insert(exclude, player.Character)
	end
	rayParams.FilterDescendantsInstances = exclude
	return workspace:Raycast(from, to, rayParams) == nil
end

local function watchTenant(model: Model)
	if tenants[model] then
		return
	end
	local root = model.PrimaryPart or model:WaitForChild("HumanoidRootPart", 5) or model:WaitForChild("Root", 5)
	if not root or not root:IsA("BasePart") then
		return
	end
	local cue = Audio.loop("TENANT_CUE", root, { group = "Entities", volume = 1.1, minDistance = 10, maxDistance = 120, fallback = "HUM", speed = 1 })
	if cue.SoundId == Audio.id("HUM") then
		cue.PlaybackSpeed = 0.22 -- stand-in until TENANT_CUE is uploaded: the hum, dragged down
	end
	-- Its screech when it spots someone: its own wet clicking breath torn
	-- up high and chattering, loud and carrying (the hum it used to be
	-- made from sank into the hum every corridor already has).
	local shriek = Instance.new("Sound")
	shriek.Name = "Shriek"
	shriek.SoundId = Audio.id("TENANT_CUE") or Audio.id("HUM") or ""
	shriek.PlaybackSpeed = 1.3
	shriek.Volume = 4
	shriek.RollOffMode = Enum.RollOffMode.InverseTapered
	shriek.RollOffMinDistance = 14
	shriek.RollOffMaxDistance = 180
	shriek.SoundGroup = Audio.group("Entities")
	local bend = Instance.new("PitchShiftSoundEffect")
	bend.Octave = 1.7
	bend.Parent = shriek
	local chatter = Instance.new("TremoloSoundEffect")
	chatter.Depth = 0.9
	chatter.Duty = 0.5
	chatter.Frequency = 13
	chatter.Parent = shriek
	local grit = Instance.new("DistortionSoundEffect")
	grit.Level = 0.55
	grit.Parent = shriek
	shriek.Parent = root

	local w: Watched = { model = model, root = root :: BasePart, cue = cue, step = nil, revealed = false, last = (root :: BasePart).Position, travelled = 0 }
	tenants[model] = w
	model:GetAttributeChangedSignal("State"):Connect(function()
		if model:GetAttribute("State") ~= "notice" then
			if shriek.IsPlaying then
				shriek:Stop()
			end
			return
		end
		if shriek.SoundId ~= "" then
			shriek.TimePosition = 0
			shriek:Play()
			task.delay(Config.TENANT.noticeSeconds, function()
				shriek:Stop()
			end)
		end
		if not myCrew(model) then
			return
		end
		if model:GetAttribute("TargetId") == player.UserId then
			-- It has seen YOU: the reveal stinger. Run.
			Audio.sting("STING_REVEAL", 1, 3)
			CameraFx.shake(0.2, 0.6)
			CameraFx.kick(8)
		else
			-- It's seen one of your crew nearby: you hear it go off too.
			local me = myRoot()
			if me and (me.Position - (root :: BasePart).Position).Magnitude < 90 then
				Audio.sting("STING_REVEAL", 0.55, 3)
			end
		end
	end)
end

local function forget(model: Model)
	tenants[model] = nil
end

CollectionService:GetInstanceAddedSignal("SHIFT_Tenant"):Connect(function(inst)
	if inst:IsA("Model") then
		watchTenant(inst)
	end
end)
CollectionService:GetInstanceRemovedSignal("SHIFT_Tenant"):Connect(function(inst)
	if inst:IsA("Model") then
		forget(inst)
	end
end)
for _, inst in CollectionService:GetTagged("SHIFT_Tenant") do
	if inst:IsA("Model") then
		task.spawn(watchTenant, inst)
	end
end

-- LAMPJAW ----------------------------------------------------------------------

local lampjawCue: Sound? = nil
local lampjawKey = 0

local function lampjawPanel(key: number): BasePart?
	if key == 0 then
		return nil
	end
	for _, inst in CollectionService:GetTagged("FlickerLight") do
		if inst:IsA("BasePart") and inst:GetAttribute("Cell") == key and myCrew(inst) then
			return inst
		end
	end
	return nil
end

local function onLampjaw()
	local key = (workspace:GetAttribute("LampjawCell") or 0) :: number
	if key == lampjawKey then
		return
	end
	lampjawKey = key
	if lampjawCue then
		lampjawCue:Destroy()
		lampjawCue = nil
	end
	local panel = lampjawPanel(key)
	if not panel then
		return
	end
	local cue = Audio.loop("LAMPJAW_CUE", panel, { group = "Entities", volume = 1, minDistance = 6, maxDistance = 70, fallback = "HUM" })
	if cue.SoundId == Audio.id("HUM") then
		cue.PlaybackSpeed = 2.4 -- stand-in: the hum as an angry buzz
	end
	lampjawCue = cue
	-- It slipped into a light right by you.
	local root = myRoot()
	if root and (root.Position - panel.Position).Magnitude < 28 then
		Audio.sting("STING_GLIMPSE", 0.7, 6)
	end
end
workspace:GetAttributeChangedSignal("LampjawCell"):Connect(onLampjaw)
onLampjaw()

-- HEARTBEAT ---------------------------------------------------------------------

local heart = Instance.new("Sound")
heart.Name = "Heartbeat"
heart.Looped = true
heart.Volume = 0
heart.SoundGroup = Audio.group("Tension")
heart.Parent = SoundService

local function nearestEntity(from: Vector3): number
	local best = math.huge
	for model, w in tenants do
		if model.Parent and myCrew(model) then
			best = math.min(best, (w.root.Position - from).Magnitude)
		end
	end
	if lampjawCue and lampjawCue.Parent and lampjawCue.Parent:IsA("BasePart") then
		-- Lampjaw only matters when you're close to its light.
		best = math.min(best, ((lampjawCue.Parent :: BasePart).Position - from).Magnitude + 20)
	end
	return best
end

local revealCheck = 0
RunService.Heartbeat:Connect(function(dt)
	local root = myRoot()
	local now = os.clock()
	-- How tense: entity proximity or low sanity, whichever is worse.
	local tension = 0
	if root then
		local d = nearestEntity(root.Position)
		tension = math.clamp(1 - (d - 15) / 70, 0, 1)
	end
	local sanity = (player:GetAttribute("Sanity") or 100) :: number
	tension = math.max(tension, math.clamp((40 - sanity) / 40, 0, 1) * 0.8)
	local id = Audio.id("HEARTBEAT")
	if id and heart.SoundId ~= id then
		heart.SoundId = id
		heart:Play()
	end
	heart.Volume += (tension * 1.1 - heart.Volume) * math.min(1, dt * 2)
	heart.PlaybackSpeed = 0.9 + tension * 0.75

	-- Each Tenant: footfalls as it moves, louder breath while it hunts,
	-- and the reveal stinger the first time you see it after it arrives.
	local checkSight = now >= revealCheck
	if checkSight then
		revealCheck = now + 0.25
	end
	for model, w in tenants do
		if not model.Parent then
			tenants[model] = nil
			continue
		end
		Audio.refresh(w.cue)
		local st = model:GetAttribute("State")
		local hunting = st == "chase" or st == "notice"
		w.cue.Volume = if hunting then 1.6 else 1.1
		local pos = w.root.Position
		local moved = (pos - w.last).Magnitude
		w.last = pos
		if moved > 5 then
			w.travelled = 0 -- it appeared somewhere new: no step for a teleport
			w.revealed = false
		else
			w.travelled += moved
			if w.travelled >= 4.5 then
				w.travelled = 0
				Audio.play("TENANT_STEP", { group = "Entities", volume = 1.5, speed = 0.55, jitter = 0.06, minDistance = 10, maxDistance = 110, fallback = "STEP_HARD" }, w.root)
			end
		end
		if checkSight and not w.revealed and myCrew(model) and visible(model, camera.CFrame.Position) then
			w.revealed = true
			Audio.sting("STING_REVEAL", 0.65, 5)
			CameraFx.kick(4)
		end
	end
	if lampjawCue then
		Audio.refresh(lampjawCue)
	end
end)

-- DEATH ------------------------------------------------------------------------

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid then
		humanoid.Died:Connect(function()
			Audio.sting("STING_DEATH", 1, 0)
		end)
	end
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

-- THE LOOP ----------------------------------------------------------------------

local function liftPos(): Vector3?
	local p = workspace:GetAttribute("LiftPosition")
	return if typeof(p) == "Vector3" then p else nil
end

local lastBanked = (workspace:GetAttribute("CrewBanked") or 0) :: number
workspace:GetAttributeChangedSignal("CrewBanked"):Connect(function()
	local banked = (workspace:GetAttribute("CrewBanked") or 0) :: number
	if banked > lastBanked and workspace:GetAttribute("CrewRunState") == "playing" then
		local at = liftPos()
		if at then
			Audio.at("DEPOSIT", at + Vector3.new(0, 3, 0), { volume = 0.9, maxDistance = 120 })
		end
	end
	lastBanked = banked
end)

local wasReady = workspace:GetAttribute("LiftReady") == true
workspace:GetAttributeChangedSignal("LiftReady"):Connect(function()
	local ready = workspace:GetAttribute("LiftReady") == true
	if ready and not wasReady then
		Audio.play("QUOTA_MET", { volume = 0.7 })
		local at = liftPos()
		if at then
			Audio.at("LIFT_DING", at + Vector3.new(0, 8, 0), { volume = 1, maxDistance = 200 })
		end
	end
	wasReady = ready
end)

local motor: Sound? = nil
local lastState = workspace:GetAttribute("CrewRunState")
workspace:GetAttributeChangedSignal("CrewRunState"):Connect(function()
	local st = workspace:GetAttribute("CrewRunState")
	if st == "descending" and not motor then
		motor = Audio.loop("LIFT_MOTOR", SoundService, { volume = 0.6 })
	elseif st ~= "descending" and motor then
		motor:Destroy()
		motor = nil
	end
	if st == "playing" and lastState == "descending" then
		Audio.play("LIFT_DING", { volume = 0.8 }) -- doors open on a new sublevel
	elseif st == "wiped" then
		Audio.sting("STING_WIPE", 1, 0)
	end
	lastState = st
end)

-- The countdown before the lift drops: a tick each second.
local lastTick = -1
RunService.Heartbeat:Connect(function()
	local st = workspace:GetAttribute("CrewRunState")
	local at = workspace:GetAttribute("DescendAt")
	if (st == "countdown" or st == "descending") and typeof(at) == "number" then
		local left = math.ceil(at - workspace:GetServerTimeNow())
		if left ~= lastTick and left >= 1 and left <= 10 then
			Audio.play("COUNTDOWN", { group = "Ui", volume = 0.5 })
		end
		lastTick = left
	else
		lastTick = -1
	end
end)

-- Sounds the server points at: loot picked up, dropped, a death.
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Fx = Remotes:WaitForChild("Fx") :: RemoteEvent
Fx.OnClientEvent:Connect(function(kind: string, position: Vector3)
	if typeof(position) ~= "Vector3" then
		return
	end
	local root = myRoot()
	if root and (root.Position - position).Magnitude > 200 then
		return -- another crew's level
	end
	if kind == "pickup" then
		Audio.at("PICKUP", position, { volume = 0.8, jitter = 0.08, maxDistance = 50 })
	elseif kind == "drop" then
		Audio.at("DROP", position, { volume = 1, jitter = 0.08, maxDistance = 120 })
	elseif kind == "death" then
		Audio.at("DROP", position, { volume = 1.2, speed = 0.6, maxDistance = 140 })
	end
end)
