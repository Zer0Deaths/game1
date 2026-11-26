-- Offline test for Crews. Run with:  luau tests/crews.test.luau
local Crews = require("../src/shared/Crews")
local failures = 0
local function check(cond, msg)
	if not cond then
		failures += 1
		print("FAIL: " .. msg)
	end
end

-- 16 players fill 4 crews of 4 evenly; the 17th has nowhere to go.
local counts = { 0, 0, 0, 0 }
for i = 1, 16 do
	local c = Crews.pick(counts, 4, 4)
	check(c ~= nil, `player {i} got no crew`)
	counts[c] += 1
	-- Never more than one apart while filling.
	local lo, hi = math.huge, 0
	for _, n in counts do
		lo, hi = math.min(lo, n), math.max(hi, n)
	end
	check(hi - lo <= 1, `uneven crews after {i} players`)
end
check(Crews.pick(counts, 4, 4) == nil, "17th player should not fit")
check(Crews.pick({ 4, 2, 4, 3 }, 4, 4) == 2, "should pick emptiest crew")

local met, nextQ, each = Crews.settle(300, 420, 3, 1.4, 300)
check(met and nextQ == 420 and each == 140, `settle met: {met} {nextQ} {each}`)
met, nextQ, each = Crews.settle(300, 200, 3, 1.4, 300)
check(not met and nextQ == 300 and each == 0, "settle failed")
met, nextQ, each = Crews.settle(300, 300, 0, 1.4, 300)
check(met and each == 0, "settle with no members")

print(if failures == 0 then "CREWS: ALL PASSED" else `CREWS: {failures} FAILURES`)
