--!strict
-- Audio: SHIFT's sound system on this device (a ModuleScript the client
-- scripts share). Every sound goes through a SoundGroup, so whole layers
-- can be faded at once:
--   Ambience  the hum Jason uploaded, the drone under it, whispers
--   Entities  each entity's 3D cue and footfalls
--   Tension   the heartbeat
--   Stingers  sharp hits for scares and reveals
--   Sfx       footsteps, loot, the lift, the flashlight
--   Ui        clicks and the shop
-- In a blackout Ambience, Entities and Tension drop to total silence
-- (Ambience.client does that with Audio.silence).
--
-- Sound IDs come from Shared.SoundIds (AssetIds.luau, written by
-- tools/upload_assets.py). A sound that isn't uploaded yet just doesn't
-- play: nothing errors.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundIds"))

local Audio = {}

local GROUP_VOLUME: { [string]: number } = {
	Ambience = 1,
	Entities = 1,
	Tension = 1,
	Stingers = 0.9,
	Sfx = 1,
	Ui = 0.6,
}

local groups: { [string]: SoundGroup } = {}
for name, volume in GROUP_VOLUME do
	local g = SoundService:FindFirstChild("SHIFT_" .. name)
	if not (g and g:IsA("SoundGroup")) then
		g = Instance.new("SoundGroup")
		g.Name = "SHIFT_" .. name
		g.Parent = SoundService
	end
	(g :: SoundGroup).Volume = volume
	groups[name] = g :: SoundGroup
end

function Audio.group(name: string): SoundGroup
	return groups[name] or groups.Sfx
end

-- The playable ID for a key, or nil if it isn't uploaded.
function Audio.id(key: string): string?
	return SoundIds.get(key)
end

-- A key or one of its numbered variants (KEY, KEY_2, KEY_3), at random.
function Audio.variant(key: string): string?
	local options = {}
	for i = 1, 4 do
		local id = SoundIds.get(if i == 1 then key else `{key}_{i}`)
		if id then
			table.insert(options, id)
		end
	end
	if #options == 0 then
		return nil
	end
	return options[math.random(1, #options)]
end

export type Options = {
	volume: number?,
	speed: number?, -- PlaybackSpeed
	jitter: number?, -- random +/- on speed, e.g. 0.05
	group: string?,
	minDistance: number?, -- 3D rolloff (only when parented to a part)
	maxDistance: number?,
	looped: boolean?,
	fallback: string?, -- another key to use if this one isn't uploaded
	variants: boolean?, -- pick KEY / KEY_2 / KEY_3 at random
}

local function make(key: string, parent: Instance, o: Options): Sound?
	local id = if o.variants then Audio.variant(key) else Audio.id(key)
	if not id and o.fallback then
		id = Audio.id(o.fallback)
	end
	if not id then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = key
	s.SoundId = id
	s.Volume = o.volume or 0.7
	s.PlaybackSpeed = (o.speed or 1) * (1 + (math.random() * 2 - 1) * (o.jitter or 0))
	s.Looped = o.looped == true
	s.SoundGroup = Audio.group(o.group or "Sfx")
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = o.minDistance or 8
	s.RollOffMaxDistance = o.maxDistance or 90
	s.Parent = parent
	return s
end

-- Fire-and-forget. With no parent it plays flat (2D) for this player only.
function Audio.play(key: string, o: Options?, parent: Instance?): Sound?
	local opts = o or {}
	local s = make(key, parent or SoundService, opts)
	if not s then
		return nil
	end
	s:Play()
	if not s.Looped then
		s.Ended:Once(function()
			s:Destroy()
		end)
		Debris:AddItem(s, 20)
	end
	return s
end

-- A one-shot at a point in the world (3D: you hear where it came from).
function Audio.at(key: string, position: Vector3, o: Options?): Sound?
	local holder = Instance.new("Attachment")
	holder.Name = "SoundAt"
	holder.WorldPosition = position
	holder.Parent = workspace.Terrain
	local s = Audio.play(key, o, holder)
	Debris:AddItem(holder, 20)
	if not s then
		holder:Destroy()
	end
	return s
end

-- A looping sound parented to something (an entity, a light). Returns
-- the Sound (not playing if the ID isn't uploaded yet) so the caller can
-- change its volume and stop it.
function Audio.loop(key: string, parent: Instance, o: Options?): Sound
	local opts = table.clone(o or {}) :: Options
	opts.looped = true
	local s = make(key, parent, opts)
	if not s then
		-- Placeholder so callers can hold on to it; filled in once the
		-- upload exists (Audio.refresh).
		s = Instance.new("Sound")
		s.Name = key
		s.Looped = true
		s.Volume = opts.volume or 0.7
		s.SoundGroup = Audio.group(opts.group or "Sfx")
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = opts.minDistance or 8
		s.RollOffMaxDistance = opts.maxDistance or 90
		s.Parent = parent
	end
	-- Remembered so Audio.refresh can swap in a fallback if this ID turns
	-- out not to load (an upload still in moderation).
	s:SetAttribute("Key", key)
	s:SetAttribute("Fallback", opts.fallback)
	s:Play()
	return s
end

-- Fill in a looping sound's ID if it has been uploaded since. Cheap.
function Audio.refresh(s: Sound)
	if s.SoundId ~= "" and not SoundIds.isBad(s.SoundId) then
		return
	end
	local key = s:GetAttribute("Key") or s.Name
	local id = Audio.id(key :: string) or (s:GetAttribute("Fallback") and Audio.id(s:GetAttribute("Fallback") :: string))
	if id then
		s.SoundId = id
		s:Play()
	end
end

local fades: { [string]: Tween } = {}
-- Fade a whole layer. silence(true) for blackouts, silence(false) after.
function Audio.fadeGroup(name: string, to: number, seconds: number)
	local g = Audio.group(name)
	if fades[name] then
		fades[name]:Cancel()
	end
	local t = TweenService:Create(g, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Volume = to })
	fades[name] = t
	t:Play()
end

function Audio.silence(on: boolean)
	for _, name in { "Ambience", "Entities", "Tension" } do
		if on then
			Audio.fadeGroup(name, 0, 0.12)
		else
			Audio.fadeGroup(name, GROUP_VOLUME[name], 1.6)
		end
	end
end

-- UI shorthand.
function Audio.ui(key: string)
	Audio.play(key, { group = "Ui", volume = 0.6, jitter = 0.03 })
end

-- Stingers never stack: one at a time, and not more than one every few seconds.
local lastSting = 0
function Audio.sting(key: string, volume: number?, minGap: number?)
	local now = os.clock()
	if now - lastSting < (minGap or 4) then
		return
	end
	lastSting = now
	Audio.play(key, { group = "Stingers", volume = volume or 0.9 })
end

return Audio
