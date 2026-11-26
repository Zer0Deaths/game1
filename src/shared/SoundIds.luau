-- Sound asset IDs. Roblox only plays sounds that are uploaded to Roblox,
-- so these start empty and the game stays silent until they are filled.
--
-- The hum file is in the repo at assets/fluorescent-hum.ogg (made by Claude,
-- no copyright issues). To turn it on:
--   1. In Studio: Window > Asset Manager > Bulk Import, pick that file.
--   2. Right-click it > Copy Asset ID.
--   3. Select Workspace, add an attribute "HumSoundId" (string) and paste
--      the ID into it, then save the place. Or send the ID to Claude to
--      put it in this file.
return {
	HUM = "", -- e.g. "rbxassetid://1234567890"
}
