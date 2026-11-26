-- Offline test for PlayerData. Run with:  luau tests/playerdata.test.luau
local PlayerData = require("../src/shared/PlayerData")
local failures = 0
local function check(cond, msg)
	if not cond then
		failures += 1
		print("FAIL: " .. msg)
	end
end

-- Round trip.
local attrs = { Cash = 1234, Own_flashlight = 1, Own_bigpack = 2, Stat_Deposited = 9000, Stat_QuotasMet = 7, Stat_Deaths = 3, Junk = "x" }
local saved = PlayerData.serialize(function(n) return attrs[n] end)
check(saved.v == PlayerData.VERSION, "version missing")
check(saved.Junk == nil, "unknown field saved")
local loaded = PlayerData.deserialize(saved)
for name in PlayerData.FIELDS do
	check(loaded[name] == attrs[name], `round trip lost {name}`)
end

-- Garbage in, defaults out.
for _, bad in { nil, 5, "hello", { Cash = "lots", Own_bigpack = 99, Stat_Deaths = -4, Own_flashlight = 0 / 0 } } do
	local d = PlayerData.deserialize(bad)
	for name, default in PlayerData.FIELDS do
		check(type(d[name]) == "number", `{name} not a number`)
	end
	check(d.Cash == 0, "bad cash should default to 0")
	check(d.Own_bigpack <= 2, "bigpack above its limit")
	check(d.Stat_Deaths >= 0, "negative stat")
	check(d.Own_flashlight == 0, "NaN should default")
end
check(PlayerData.deserialize({ Cash = 12.7 }).Cash == 12, "cash should be whole")

print(if failures == 0 then "PLAYERDATA: ALL PASSED" else `PLAYERDATA: {failures} FAILURES`)
