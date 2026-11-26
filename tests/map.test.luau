-- Offline test for MapKnowledge. Run with:  luau tests/map.test.luau
local LevelGen = require("../src/shared/LevelGen")
local MapKnowledge = require("../src/shared/MapKnowledge")

local failures = 0
local function check(cond, msg)
	if not cond then
		failures += 1
		print("FAIL: " .. msg)
	end
end

for seed = 1, 100 do
	local layout = LevelGen.generate(seed)
	local know = {}
	-- Stand at spawn: own cell is known with the right walls.
	local changed = MapKnowledge.reveal(know, layout, 1, 1, 0, 2)
	check(#changed >= 1 and know[1001] ~= nil, `seed {seed}: spawn not revealed`)
	-- Every revealed cell's mask matches the real walls.
	for key, e in know do
		check(e.mask == MapKnowledge.maskOf(layout, key // 1000, key % 1000), `seed {seed}: wrong mask`)
	end
	-- Revealing again changes nothing.
	check(#MapKnowledge.reveal(know, layout, 1, 1, 0, 2) == 0, `seed {seed}: repeat reveal changed entries`)
	-- After a Shift, the same spot reports entries again (new shift number).
	LevelGen.shift(layout, { [1001] = true }, seed)
	check(#MapKnowledge.reveal(know, layout, 1, 1, 1, 2) >= 1, `seed {seed}: post-shift reveal empty`)
	-- Line of sight never passes through a wall: each revealed straight-line cell is reachable.
	local dist = LevelGen.distancesFrom(layout, 1, 1)
	for key, e in know do
		if e.shift == 1 then
			check(dist[key] ~= nil and dist[key] <= 2, `seed {seed}: saw through a wall`)
		end
	end
end
print(if failures == 0 then "MAP: ALL PASSED" else `MAP: {failures} FAILURES`)
