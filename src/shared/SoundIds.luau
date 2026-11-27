-- Sound asset IDs. Roblox only plays sounds that are uploaded to Roblox.
-- Each sound stays off (or falls back to another) until its ID exists.
--
-- Most IDs now come from AssetIds.luau, which tools/upload_assets.py
-- writes after uploading everything in assets/sounds (see TODO.md).
-- The four originals, in the repo's assets/ folder:
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

local AssetIds = require(script.Parent:WaitForChild("AssetIds"))

local SoundIds = {
	HUM = "131198792468287", -- Jason's fluorescent hum (keep it: everything is layered on top)
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

-- New uploads can sit in Roblox's audio moderation for a while ("Asset is
-- not approved for the requester"). verify() checks every uploaded ID once
-- on the client; one that won't load is marked bad and skipped, so the
-- sound falls back to the older upload or stand-in instead of failing on
-- every footstep. Until the check finishes, an older ID is preferred.
local bad: { [string]: boolean } = {}
local verified = false
local changed = Instance.new("BindableEvent")

local function usable(id: string?): string?
	if id and not bad[id] then
		return id
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
	local first = usable(normalise(fromWorkspace)) or usable(normalise((SoundIds :: any)[key]))
	if first then
		return first
	end
	local uploaded = usable(normalise((AssetIds.sounds :: any)[key]))
	local older = usable(resolved[key])
	if not verified and older then
		return older
	end
	return uploaded or older
end

local function isBad(id: string): boolean
	return bad[id] == true
end

-- Client only. Checks every uploaded sound loads; marks the ones that
-- don't. Runs in the background; fires Changed when done.
local verifying = false
local function verify()
	if verifying then
		return
	end
	verifying = true
	task.spawn(function()
		local list, keyOf = {}, {}
		for key, raw in AssetIds.sounds :: any do
			local id = normalise(raw)
			if id then
				if not keyOf[id] then
					table.insert(list, id)
				end
				keyOf[id] = key
			end
		end
		local failed = {}
		-- Load each one into a silent Sound and wait for it. PreloadAsync
		-- reports success even for audio Roblox hasn't approved yet; a
		-- Sound that is still not loaded after the wait is the real test.
		local SoundService = game:GetService("SoundService")
		local probes = {}
		for _, id in list do
			local probe = Instance.new("Sound")
			probe.Name = "SoundIdsProbe"
			probe.SoundId = id
			probe.Volume = 0
			probe.Parent = SoundService
			table.insert(probes, probe)
		end
		local deadline = os.clock() + 12
		while os.clock() < deadline do
			local waiting = false
			for _, probe in probes do
				if not probe.IsLoaded then
					waiting = true
					break
				end
			end
			if not waiting then
				break
			end
			task.wait(0.2)
		end
		for _, probe in probes do
			if not probe.IsLoaded or probe.TimeLength <= 0 then
				bad[probe.SoundId] = true
				table.insert(failed, `{keyOf[probe.SoundId] or "?"} ({string.match(probe.SoundId, "%d+") or probe.SoundId})`)
			end
		end
		for _, probe in probes do
			probe:Destroy()
		end
		verified = true
		if #list > 3 and #failed == #list then
			-- Every single one failing means the check is wrong, not the
			-- sounds: don't throw them all away.
			table.clear(bad)
			warn(`[SoundIds] couldn't check the uploaded sounds (all {#list} reported failing); using them anyway`)
			changed:Fire()
			return
		end
		if #failed > 0 then
			table.sort(failed)
			warn(`[SoundIds] {#failed} uploaded sound(s) can't load yet (Roblox may still be reviewing them); using fallbacks: {table.concat(failed, ", ")}`)
		else
			print(`[SoundIds] all {#list} uploaded sounds load`)
		end
		changed:Fire()
	end)
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
	isBad = isBad,
	verify = verify,
	Changed = changed.Event,
	autoAssign = autoAssign,
}
