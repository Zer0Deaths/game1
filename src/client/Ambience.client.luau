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
