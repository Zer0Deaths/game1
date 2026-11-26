-- Looping fluorescent hum, played locally on each player's device.
-- Silent until a hum sound ID is set (see ReplicatedStorage.Shared.SoundIds).
-- A Workspace attribute "HumSoundId" overrides the file, so the ID can be
-- set in Studio without touching code.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundIds"))

local function normalise(id: any): string?
	if typeof(id) == "number" then
		return `rbxassetid://{id}`
	elseif typeof(id) == "string" and id ~= "" then
		return if string.match(id, "^%d+$") then `rbxassetid://{id}` else id
	end
	return nil
end

local hum = Instance.new("Sound")
hum.Name = "FluorescentHum"
hum.Looped = true
hum.Volume = 0.35
hum.Parent = SoundService

local function refresh()
	local id = normalise(workspace:GetAttribute("HumSoundId")) or normalise(SoundIds.HUM)
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

workspace:GetAttributeChangedSignal("HumSoundId"):Connect(refresh)
refresh()
