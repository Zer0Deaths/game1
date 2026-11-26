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
