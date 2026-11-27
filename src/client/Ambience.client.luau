--!strict
-- The ambient bed, played on this device:
--   * Jason's looping fluorescent hum (HUM), the base of everything.
--   * DRONE: a low room tone underneath the hum, always on. Until DRONE
--     is uploaded the hum slowed right down stands in for it.
--   * WHISPERS: fade in as your Sanity falls (player attribute, 0-100).
-- The Shift, in sound:
--   warning:  the hum climbs in pitch and gets louder, SHIFT_WARN whines up
--   blackout: a heavy relay THUNK, then TOTAL SILENCE: hum, drone,
--             entities and heartbeat all cut (Audio.silence)
--   lights back: relays clack (LIGHTS_ON) and the bed fades back in

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundIds"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local player = Players.LocalPlayer
local HUM_VOLUME = 0.35
local DRONE_VOLUME = 0.5

local function bedSound(name: string, volume: number, speed: number): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.Looped = true
	s.Volume = volume
	s.PlaybackSpeed = speed
	s.SoundGroup = Audio.group("Ambience")
	s.Parent = SoundService
	return s
end

local hum = bedSound("FluorescentHum", HUM_VOLUME, 1)
local drone = bedSound("Drone", DRONE_VOLUME, 1)
local whispers = bedSound("Whispers", 0, 1)

-- Pick up IDs as they become known (uploads, Workspace attributes, the
-- old auto-assign of Jason's first four uploads).
local function refresh()
	local humId = SoundIds.get("HUM")
	if humId and hum.SoundId ~= humId then
		hum.SoundId = humId
		hum:Play()
	end
	local droneId = SoundIds.get("DRONE")
	if droneId then
		if drone.SoundId ~= droneId then
			drone.SoundId = droneId
			drone.PlaybackSpeed = 1
			drone.Volume = DRONE_VOLUME
			drone:Play()
		end
	elseif humId and drone.SoundId ~= humId then
		-- Stand-in until DRONE is uploaded: the hum, slowed to a rumble.
		drone.SoundId = humId
		drone.PlaybackSpeed = 0.3
		drone.Volume = 0.3
		drone:Play()
	end
	local whisperId = SoundIds.get("WHISPERS")
	if whisperId and whispers.SoundId ~= whisperId then
		whispers.SoundId = whisperId
		whispers:Play()
	end
end

for _, key in { "HUM", "HumSoundId", "DRONE", "WHISPERS" } do
	workspace:GetAttributeChangedSignal(key):Connect(refresh)
end
refresh()
SoundIds.autoAssign() -- works out which of Jason's first uploads is which
refresh()

local humTween: Tween? = nil
local function tweenHum(seconds: number, goal: { [string]: number })
	if humTween then
		humTween:Cancel()
	end
	humTween = TweenService:Create(hum, TweenInfo.new(seconds, Enum.EasingStyle.Sine), goal)
	;(humTween :: Tween):Play()
end

local mode = "normal"
local function onShiftState()
	local wanted = if workspace:GetAttribute("Shifting")
		then "blackout"
		elseif workspace:GetAttribute("ShiftWarning") then "warning"
		else "normal"
	if wanted == mode then
		return
	end
	local was = mode
	mode = wanted
	if mode == "warning" then
		tweenHum(5, { PlaybackSpeed = 1.8, Volume = 0.7 })
		Audio.play("SHIFT_WARN", { volume = 0.45 })
	elseif mode == "blackout" then
		Audio.play("BLACKOUT", { volume = 0.9 })
		Audio.silence(true) -- total silence while the maze rewires
		print("[Audio] blackout: ambience, entities and heartbeat silenced")
	else
		tweenHum(0.05, { PlaybackSpeed = 1, Volume = HUM_VOLUME })
		if was == "blackout" then
			Audio.play("LIGHTS_ON", { volume = 0.8 })
		end
		Audio.silence(false)
		if was == "blackout" then
			print("[Audio] lights back: ambience restored")
		end
	end
end
workspace:GetAttributeChangedSignal("ShiftWarning"):Connect(onShiftState)
workspace:GetAttributeChangedSignal("Shifting"):Connect(onShiftState)
onShiftState()

-- Whispers follow sanity (Sanity.client sets it; 100 = fine).
task.spawn(function()
	while true do
		task.wait(0.25)
		refresh()
		local sanity = (player:GetAttribute("Sanity") or 100) :: number
		local target = math.clamp((45 - sanity) / 45, 0, 1) * 0.55
		whispers.Volume += (target - whispers.Volume) * 0.15
	end
end)
