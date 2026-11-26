-- Offline test for LevelGen. Run with the Luau CLI:  luau tests/levelgen.test.luau
-- (Not synced into Studio.)
local LevelGen = require("../src/shared/LevelGen")

local failures = 0
local function check(cond: boolean, msg: string)
	if not cond then
		failures += 1
		print("FAIL: " .. msg)
	end
end

for seed = 1, 300 do
	local layout = LevelGen.generate(seed)
	local total = layout.width * layout.depth
	check(LevelGen.reachableCount(layout) == total, `seed {seed}: some cells unreachable`)
	for x = 1, layout.width do
		check(layout.cells[x][layout.depth].wallSouth, `seed {seed}: south border open`)
	end
	for z = 1, layout.depth do
		check(layout.cells[layout.width][z].wallEast, `seed {seed}: east border open`)
	end
	check(layout.cells[1][1].light == "on", `seed {seed}: spawn dark`)
	local ex = layout.exit
	check(not (ex.x == 1 and ex.z == 1), `seed {seed}: exit on spawn`)
	local dist = LevelGen.distancesFrom(layout, 1, 1)
	check(dist[ex.x * 1000 + ex.z] ~= nil and dist[ex.x * 1000 + ex.z] >= 8, `seed {seed}: exit too close`)
end

-- Same seed must give the same level.
local a, b = LevelGen.generate(42), LevelGen.generate(42)
for x = 1, a.width do
	for z = 1, a.depth do
		check(
			a.cells[x][z].wallEast == b.cells[x][z].wallEast and a.cells[x][z].wallSouth == b.cells[x][z].wallSouth,
			"seed 42 not deterministic"
		)
	end
end

-- Different seeds should differ.
local c = LevelGen.generate(43)
local diff = 0
for x = 1, a.width do
	for z = 1, a.depth do
		if a.cells[x][z].wallEast ~= c.cells[x][z].wallEast then
			diff += 1
		end
	end
end
check(diff > 10, "seeds 42 and 43 nearly identical")

-- Print one map so a human can eyeball it. S = spawn, . = room.
local l = LevelGen.generate(7)
local lines = { "+" .. string.rep("---+", l.width) }
for z = 1, l.depth do
	local row, under = "|", "+"
	for x = 1, l.width do
		local mark = if x == 1 and z == 1 then " S " elseif l.cells[x][z].room then " . " else "   "
		row ..= mark .. (if l.cells[x][z].wallEast then "|" else " ")
		under ..= (if l.cells[x][z].wallSouth then "---" else "   ") .. "+"
	end
	table.insert(lines, row)
	table.insert(lines, under)
end
print(table.concat(lines, "\n"))

print(if failures == 0 then "ALL PASSED" else `{failures} FAILURES`)

-- THE SHIFT: protected cells keep every wall, the maze stays connected,
-- and the exit lands somewhere valid.
local shiftFailures = 0
for seed = 1, 200 do
	local layout = LevelGen.generate(seed)
	local rng = LevelGen.makeRng(seed * 7)
	for round = 1, 5 do
		-- 1-4 "players", each protecting their cell and neighbours.
		local protected = {}
		for _ = 1, rng.int(1, 4) do
			local px, pz = rng.int(1, layout.width), rng.int(1, layout.depth)
			for dx = -1, 1 do
				for dz = -1, 1 do
					local x, z = px + dx, pz + dz
					if x >= 1 and x <= layout.width and z >= 1 and z <= layout.depth then
						protected[x * 1000 + z] = true
					end
				end
			end
		end
		-- Snapshot walls touching protected cells.
		local before = {}
		for k in protected do
			local x, z = k // 1000, k % 1000
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				before[`{x},{z},{d[1]},{d[2]}`] = LevelGen.hasWall(layout, x, z, d[1], d[2])
			end
		end
		LevelGen.shift(layout, protected, seed * 100 + round)
		local total = layout.width * layout.depth
		if LevelGen.reachableCount(layout) ~= total then
			shiftFailures += 1
			check(false, `shift seed {seed} round {round}: maze split`)
		end
		for key, had in before do
			local x, z, dx, dz = string.match(key, "(-?%d+),(-?%d+),(-?%d+),(-?%d+)")
			local now = LevelGen.hasWall(layout, tonumber(x) :: number, tonumber(z) :: number, tonumber(dx) :: number, tonumber(dz) :: number)
			check(now == had, `shift seed {seed} round {round}: protected wall {key} changed`)
		end
		local ex = layout.exit
		check(ex.x >= 1 and ex.x <= layout.width and ex.z >= 1 and ex.z <= layout.depth, `shift seed {seed}: exit off grid`)
		check(layout.cells[ex.x][ex.z].light == "on", `shift seed {seed}: exit dark`)
	end
end
print(`shift rounds checked: 1000, maze splits: {shiftFailures}`)
print(if failures == 0 then "ALL PASSED (incl. shift)" else `{failures} FAILURES`)
