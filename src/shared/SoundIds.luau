-- Sound asset IDs. Roblox only plays sounds that are uploaded to Roblox,
-- so these start empty. Each sound stays off (or falls back to Roblox's
-- default) until its ID is filled in.
--
-- The files are in the repo's assets/ folder, made by Claude, so there
-- are no copyright issues:
--   HUM             assets/fluorescent-hum.ogg
--   STEP_CARPET     assets/footstep-carpet.ogg
--   STEP_HARD       assets/footstep-hard.ogg
--   STEP_METAL      assets/footstep-metal.ogg
--
-- To turn one on without touching code: upload it in Studio
-- (Window > Asset Manager > Bulk Import), copy its asset ID, select
-- Workspace and add a string attribute with the same name as the key
-- (for example STEP_CARPET), paste the ID, and save the place.
-- Or send the IDs to Claude to put in the table below.

local SoundIds = {
	HUM = "",
	STEP_CARPET = "",
	STEP_HARD = "",
	STEP_METAL = "",
}

-- Jason's 4 uploads (2026-11-26). Which ID is which sound wasn't recorded,
-- so autoAssign() works it out on the client from each sound's length:
-- hum 10 s > metal 0.6 s > carpet 0.32 s > hard 0.25 s.
-- Output prints the result; once confirmed, copy it into the table above.
local UPLOADED = {
	"102571683177289",
	"118153125404738",
	"118990638940111",
	"131198792468287",
}
local LENGTH_ORDER = { "HUM", "STEP_METAL", "STEP_CARPET", "STEP_HARD" } -- longest first
local resolved: { [string]: string } = {}
local assigning = false

local function normalise(id: any): string?
	if typeof(id) == "number" then
		return `rbxassetid://{id}`
	elseif typeof(id) == "string" and id ~= "" then
		return if string.match(id, "^%d+$") then `rbxassetid://{id}` else id
	end
	return nil
end

-- Returns a playable SoundId, or nil if that sound isn't uploaded yet.
-- A Workspace attribute wins over the table. "HumSoundId" still works for the hum.
local function get(key: string): string?
	local fromWorkspace = workspace:GetAttribute(key)
	if key == "HUM" and fromWorkspace == nil then
		fromWorkspace = workspace:GetAttribute("HumSoundId")
	end
	return normalise(fromWorkspace) or normalise((SoundIds :: any)[key]) or resolved[key]
end

-- Client only. Loads the uploaded sounds, sorts them by length and maps
-- them to keys. Safe to call more than once; yields up to ~10 s.
local function autoAssign()
	if assigning or #UPLOADED == 0 then
		return
	end
	assigning = true
	local SoundService = game:GetService("SoundService")
	local probes = {}
	for _, id in UPLOADED do
		local sound = Instance.new("Sound")
		sound.SoundId = `rbxassetid://{id}`
		sound.Volume = 0
		sound.Parent = SoundService
		table.insert(probes, { id = id, sound = sound })
	end
	local deadline = os.clock() + 10
	for _, probe in probes do
		while not probe.sound.IsLoaded and os.clock() < deadline do
			task.wait(0.1)
		end
	end
	local loaded = {}
	for _, probe in probes do
		if probe.sound.IsLoaded and probe.sound.TimeLength > 0 then
			table.insert(loaded, { id = probe.id, length = probe.sound.TimeLength })
		end
		probe.sound:Destroy()
	end
	if #loaded ~= #LENGTH_ORDER then
		warn(`[SoundIds] only {#loaded} of {#UPLOADED} uploaded sounds loaded; check they are public/owned by this game`)
		return
	end
	table.sort(loaded, function(a, b)
		return a.length > b.length
	end)
	for i, key in LENGTH_ORDER do
		resolved[key] = `rbxassetid://{loaded[i].id}`
		print(`[SoundIds] {key} = {loaded[i].id} ({string.format("%.2f", loaded[i].length)} s)`)
	end
end

return {
	ids = SoundIds,
	get = get,
	autoAssign = autoAssign,
}
