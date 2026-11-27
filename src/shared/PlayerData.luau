--!strict
-- What gets saved for each player, and how it is checked on the way in.
-- Pure functions so they can be tested offline. Saved data is validated
-- field by field: anything missing, the wrong type, or out of range falls
-- back to the default, so a bad save can never break the game.

local PlayerData = {}

PlayerData.VERSION = 1

-- Attribute name -> default. Only these are saved.
PlayerData.FIELDS = {
	Cash = 0,
	Own_flashlight = 0,
	Own_bigpack = 0,
	Stat_Deposited = 0, -- lifetime value deposited at exit lifts
	Stat_QuotasMet = 0, -- sublevels your crew cleared
	Stat_Deaths = 0,
	Stat_Deepest = 0, -- deepest sublevel reached
}

local LIMITS = {
	Own_flashlight = 1,
	Own_bigpack = 2,
}

local MAX_NUMBER = 1e12

local function clean(name: string, value: unknown): number
	local default = PlayerData.FIELDS[name] :: number
	if typeof(value) ~= "number" or value ~= value then -- not a number, or NaN
		return default
	end
	local n = math.floor(math.clamp(value :: number, 0, MAX_NUMBER))
	local limit = LIMITS[name]
	if limit then
		n = math.min(n, limit)
	end
	return n
end

-- Read the saved fields off a player's attributes (via a getter).
function PlayerData.serialize(get: (string) -> unknown): { [string]: any }
	local out: { [string]: any } = { v = PlayerData.VERSION }
	for name in PlayerData.FIELDS do
		out[name] = clean(name, get(name))
	end
	return out
end

-- Turn whatever came out of the DataStore into safe attribute values.
function PlayerData.deserialize(saved: unknown): { [string]: number }
	local out: { [string]: number } = {}
	local data = if typeof(saved) == "table" then saved :: { [string]: unknown } else {}
	for name in PlayerData.FIELDS do
		out[name] = clean(name, data[name])
	end
	return out
end

return PlayerData
