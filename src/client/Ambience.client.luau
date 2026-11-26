-- Looping fluorescent hum, played locally on each player's device.
-- Silent until the HUM sound ID is set (see ReplicatedStorage.Shared.SoundIds).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundIds"))

local hum = Instance.new("Sound")
hum.Name = "FluorescentHum"
hum.Looped = true
hum.Volume = 0.35
hum.Parent = SoundService

local function refresh()
	local id = SoundIds.get("HUM")
	if not id then
		hum:Stop()
		return
	end
	if hum.SoundId ~= id then
		hum.SoundId = id
	end
	if not hum.IsPlaying then
		hum:Play()
	end
end

workspace:GetAttributeChangedSignal("HUM"):Connect(refresh)
workspace:GetAttributeChangedSignal("HumSoundId"):Connect(refresh)
refresh()

-- Work out which uploaded sound is which (footsteps pick this up too).
SoundIds.autoAssign()
refresh()

-- The Shift, in sound only (no camera effects):
--   warning:  the hum climbs in pitch and gets louder
--   blackout: the hum cuts out and a deep rumble (same file, slowed way down) takes over
local TweenService = game:GetService("TweenService")

local rumble = Instance.new("Sound")
rumble.Name = "ShiftRumble"
rumble.Looped = true
rumble.Volume = 0
rumble.PlaybackSpeed = 0.3
rumble.Parent = SoundService

local function tween(sound: Sound, seconds: number, goal: { [string]: number })
	TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Sine), goal):Play()
end

local function onShiftState()
	local id = SoundIds.get("HUM")
	if id and rumble.SoundId ~= id then
		rumble.SoundId = id
	end
	if workspace:GetAttribute("Shifting") then
		tween(hum, 0.2, { Volume = 0 })
		if id then
			rumble:Play()
		end
		tween(rumble, 0.3, { Volume = 0.9 })
	elseif workspace:GetAttribute("ShiftWarning") then
		tween(hum, 5, { PlaybackSpeed = 1.8, Volume = 0.7 })
	else
		tween(rumble, 1.2, { Volume = 0 })
		hum.PlaybackSpeed = 1
		tween(hum, 1.5, { Volume = 0.35 })
	end
end
workspace:GetAttributeChangedSignal("ShiftWarning"):Connect(onShiftState)
workspace:GetAttributeChangedSignal("Shifting"):Connect(onShiftState)
