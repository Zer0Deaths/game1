--!strict
-- LevelGen: builds the LAYOUT of a level as plain data (no parts).
-- The server turns this data into parts with LevelBuilder.
-- Keeping layout separate from parts means the Shift can later
-- regenerate only the cells nobody is looking at.
--
-- Grid: cells are numbered x = 1..width (east), z = 1..depth (south).
-- Each cell stores whether its EAST and SOUTH walls exist.
-- The outer border is always solid.

local LevelGen = {}

export type Cell = {
	x: number,
	z: number,
	wallEast: boolean,
	wallSouth: boolean,
	room: number?, -- id of the room this cell belongs to, nil for corridors
	light: "on" | "flicker" | "dead",
}

export type Layout = {
	seed: number,
	width: number,
	depth: number,
	cells: { { Cell } }, -- cells[x][z]
	rooms: { { x: number, z: number, w: number, d: number } },
	spawn: { x: number, z: number },
	exit: { x: number, z: number }, -- exit lift, the reachable cell furthest from spawn
}

export type Options = {
	width: number?,
	depth: number?,
	loopChance: number?, -- extra walls knocked out after the maze, 0..1
	roomCount: number?,
	flickerChance: number?,
	deadChance: number?,
}

-- Small seeded random generator (Park-Miller). Same seed, same level,
-- in Studio and in the offline tests.
local function makeRng(seed: number)
	local state = math.floor(math.abs(seed)) % 2147483646 + 1
	local rng = {}
	function rng.float(): number
		state = (state * 16807) % 2147483647
		return (state - 1) / 2147483646
	end
	function rng.int(lo: number, hi: number): number
		return lo + math.floor(rng.float() * (hi - lo + 1))
	end
	return rng
end
LevelGen.makeRng = makeRng

local function inBounds(layout: Layout, x: number, z: number): boolean
	return x >= 1 and x <= layout.width and z >= 1 and z <= layout.depth
end

-- Is there a wall between cell (x, z) and its neighbour (x+dx, z+dz)?
function LevelGen.hasWall(layout: Layout, x: number, z: number, dx: number, dz: number): boolean
	local nx, nz = x + dx, z + dz
	if not inBounds(layout, nx, nz) then
		return true
	end
	if dx == 1 then
		return layout.cells[x][z].wallEast
	elseif dx == -1 then
		return layout.cells[nx][nz].wallEast
	elseif dz == 1 then
		return layout.cells[x][z].wallSouth
	else
		return layout.cells[nx][nz].wallSouth
	end
end

local function setWall(layout: Layout, x: number, z: number, dx: number, dz: number, value: boolean)
	local nx, nz = x + dx, z + dz
	if not inBounds(layout, nx, nz) then
		return -- border walls never open
	end
	if dx == 1 then
		layout.cells[x][z].wallEast = value
	elseif dx == -1 then
		layout.cells[nx][nz].wallEast = value
	elseif dz == 1 then
		layout.cells[x][z].wallSouth = value
	else
		layout.cells[nx][nz].wallSouth = value
	end
end
LevelGen.setWall = setWall

local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

function LevelGen.generate(seed: number, options: Options?): Layout
	local opts: Options = options or {} :: Options
	local width = opts.width or 14
	local depth = opts.depth or 14
	local loopChance = opts.loopChance or 0.18
	local roomCount = opts.roomCount or 4
	local flickerChance = opts.flickerChance or 0.12
	local deadChance = opts.deadChance or 0.2
	local rng = makeRng(seed)

	-- 1. Start with every wall standing.
	local cells: { { Cell } } = {}
	for x = 1, width do
		cells[x] = {}
		for z = 1, depth do
			cells[x][z] = { x = x, z = z, wallEast = true, wallSouth = true, room = nil, light = "on" }
		end
	end
	local layout: Layout = {
		seed = seed,
		width = width,
		depth = depth,
		cells = cells,
		rooms = {},
		spawn = { x = 1, z = 1 },
		exit = { x = width, z = depth },
	}

	-- 2. Carve a maze (randomised depth-first search). Every cell becomes reachable.
	local visited: { [number]: boolean } = {}
	local function key(x: number, z: number): number
		return x * 1000 + z
	end
	local stack = { { 1, 1 } }
	visited[key(1, 1)] = true
	while #stack > 0 do
		local top = stack[#stack]
		local x, z = top[1], top[2]
		local options_ = {}
		for _, d in DIRS do
			local nx, nz = x + d[1], z + d[2]
			if inBounds(layout, nx, nz) and not visited[key(nx, nz)] then
				table.insert(options_, d)
			end
		end
		if #options_ == 0 then
			table.remove(stack)
		else
			local d = options_[rng.int(1, #options_)]
			setWall(layout, x, z, d[1], d[2], false)
			visited[key(x + d[1], z + d[2])] = true
			table.insert(stack, { x + d[1], z + d[2] })
		end
	end

	-- 3. Knock out extra walls so there are loops. Pure mazes feel like puzzles;
	-- loops feel like being lost, which is the point.
	for x = 1, width do
		for z = 1, depth do
			if x < width and cells[x][z].wallEast and rng.float() < loopChance then
				cells[x][z].wallEast = false
			end
			if z < depth and cells[x][z].wallSouth and rng.float() < loopChance then
				cells[x][z].wallSouth = false
			end
		end
	end

	-- 4. Open rooms: rectangles with every inner wall removed.
	for id = 1, roomCount do
		local w, d = rng.int(2, 4), rng.int(2, 4)
		local rx, rz = rng.int(1, width - w + 1), rng.int(1, depth - d + 1)
		table.insert(layout.rooms, { x = rx, z = rz, w = w, d = d })
		for x = rx, rx + w - 1 do
			for z = rz, rz + d - 1 do
				cells[x][z].room = id
				if x < rx + w - 1 then
					cells[x][z].wallEast = false
				end
				if z < rz + d - 1 then
					cells[x][z].wallSouth = false
				end
			end
		end
	end

	-- 5. Lights: most work, some flicker, some are dead (dark patches).
	for x = 1, width do
		for z = 1, depth do
			local roll = rng.float()
			if roll < deadChance then
				cells[x][z].light = "dead"
			elseif roll < deadChance + flickerChance then
				cells[x][z].light = "flicker"
			end
		end
	end
	-- Spawn cell is always lit so players don't start blind.
	cells[1][1].light = "on"

	-- 6. Exit lift goes in the cell that takes longest to walk to.
	-- Ties go to the lowest key so the same seed always picks the same cell.
	local best, bestDist, bestKey = layout.exit, -1, math.huge
	for k, dist in LevelGen.distancesFrom(layout, 1, 1) do
		if dist > bestDist or (dist == bestDist and k < bestKey) then
			bestDist, bestKey = dist, k
			best = { x = k // 1000, z = k % 1000 }
		end
	end
	layout.exit = best
	cells[best.x][best.z].light = "on"

	return layout
end

-- Walking distance (in cells) from (sx, sz) to every reachable cell.
-- Keys are x * 1000 + z.
function LevelGen.distancesFrom(layout: Layout, sx: number, sz: number): { [number]: number }
	local dist: { [number]: number } = { [sx * 1000 + sz] = 0 }
	local queue = { { sx, sz } }
	local head = 1
	while head <= #queue do
		local x, z = queue[head][1], queue[head][2]
		head += 1
		local here = dist[x * 1000 + z]
		for _, d in DIRS do
			local nx, nz = x + d[1], z + d[2]
			local k = nx * 1000 + nz
			if dist[k] == nil and not LevelGen.hasWall(layout, x, z, d[1], d[2]) then
				dist[k] = here + 1
				table.insert(queue, { nx, nz })
			end
		end
	end
	return dist
end

-- Counts cells reachable from the spawn. Used by tests to prove
-- the level never traps a player.
function LevelGen.reachableCount(layout: Layout): number
	local seen: { [number]: boolean } = {}
	local queue = { { layout.spawn.x, layout.spawn.z } }
	seen[layout.spawn.x * 1000 + layout.spawn.z] = true
	local count = 0
	local head = 1
	while head <= #queue do
		local x, z = queue[head][1], queue[head][2]
		head += 1
		count += 1
		for _, d in DIRS do
			local nx, nz = x + d[1], z + d[2]
			local k = nx * 1000 + nz
			if not seen[k] and not LevelGen.hasWall(layout, x, z, d[1], d[2]) then
				seen[k] = true
				table.insert(queue, { nx, nz })
			end
		end
	end
	return count
end

return LevelGen
