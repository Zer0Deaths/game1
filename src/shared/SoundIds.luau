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
	return normalise(fromWorkspace) or normalise((SoundIds :: any)[key])
end

return {
	ids = SoundIds,
	get = get,
}
