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

-- Quota scales with crew size and depth.
check(Crews.quota(1, 1, 250, 100, 1.35) == 250, "solo quota")
check(Crews.quota(1, 4, 250, 100, 1.35) == 550, "crew of 4 quota")
check(Crews.quota(2, 4, 250, 100, 1.35) == 740, `depth 2 quota {Crews.quota(2, 4, 250, 100, 1.35)}`)
check(Crews.quota(5, 4, 250, 100, 1.35) > Crews.quota(4, 4, 250, 100, 1.35), "quota grows")
check(Crews.lootMultiplier(1, 0.2) == 1 and math.abs(Crews.lootMultiplier(3, 0.2) - 1.4) < 1e-9, "loot multiplier")
check(Crews.levelSize(1, { 22, 26, 28, 30 }) == 22 and Crews.levelSize(9, { 22, 26, 28, 30 }) == 30 and Crews.levelSize(0, { 22, 26, 28, 30 }) == 22, "level size")
check(Crews.split(550, 4) == 137 and Crews.split(100, 0) == 0, "split")

-- The loot a level holds keeps the quota reachable for a while, then it
-- gets hard: quota as a share of all the loot in the level, by depth.
local avgValue = 41.5 -- average artefact value on sublevel 1 (Artefacts.luau rarities)
for members = 1, 4 do
	local size = Crews.levelSize(members, { 22, 26, 28, 30 })
	local loot = math.floor(size * size * 8 / 100) * avgValue
	local share1 = Crews.quota(1, members, 250, 100, 1.35) / loot
	local share6 = Crews.quota(6, members, 250, 100, 1.35) / (loot * Crews.lootMultiplier(6, 0.2))
	check(share1 < 0.4, `crew of {members}: sublevel 1 needs {math.floor(share1 * 100)}% of the loot`)
	check(share6 > share1, `crew of {members}: deeper should be harder`)
	print(`crew of {members}: sublevel 1 needs {math.floor(share1 * 100)}% of the loot, sublevel 6 needs {math.floor(share6 * 100)}%`)
end

print(if failures == 0 then "CREWS: ALL PASSED" else `CREWS: {failures} FAILURES`)
