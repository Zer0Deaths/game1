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

-- Shortest walking route between two cells, as a list of cells from the
-- one after the start up to and including the goal ({} if already there,
-- nil if unreachable). Used by entities to walk the maze.
function LevelGen.path(layout: Layout, sx: number, sz: number, tx: number, tz: number): { { number } }?
	if sx == tx and sz == tz then
		return {}
	end
	local from: { [number]: number } = { [sx * 1000 + sz] = -1 }
	local queue = { { sx, sz } }
	local head = 1
	local goal = tx * 1000 + tz
	while head <= #queue do
		local x, z = queue[head][1], queue[head][2]
		head += 1
		for _, d in DIRS do
			local nx, nz = x + d[1], z + d[2]
			local k = nx * 1000 + nz
			if from[k] == nil and not LevelGen.hasWall(layout, x, z, d[1], d[2]) then
				from[k] = x * 1000 + z
				if k == goal then
					local route = {}
					local cur = k
					while cur ~= sx * 1000 + sz do
						table.insert(route, 1, { cur // 1000, cur % 1000 })
						cur = from[cur]
					end
					return route
				end
				table.insert(queue, { nx, nz })
			end
		end
	end
	return nil
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

export type ShiftOptions = {
	loopChance: number?,
	newRooms: number?,
	flickerChance: number?,
	deadChance: number?,
	minExitDistance: number?, -- cells between the moved lift and the nearest protected cell
}

-- THE SHIFT. Rewires every part of the maze except the protected cells
-- (the ones players are standing in or next to), in place.
--
-- protected: set of keys (x * 1000 + z) that must not visibly change.
-- Any wall touching a protected cell keeps its current state. Every other
-- wall is re-rolled as a fresh random spanning tree plus loops, so the
-- whole level stays connected: the old open walls prove a connected
-- layout exists, and a spanning tree over (kept open walls + all
-- re-rollable walls) always finds one.
--
-- The exit lift moves to a fresh unprotected cell far from players,
-- unless someone is standing near it.
-- Returns how many walls changed (opened or closed).
function LevelGen.shift(layout: Layout, protected: { [number]: boolean }, seed: number, options: ShiftOptions?): number
	local opts: ShiftOptions = options or {} :: ShiftOptions
	local loopChance = opts.loopChance or 0.18
	local newRooms = opts.newRooms or 2
	local flickerChance = opts.flickerChance or 0.12
	local deadChance = opts.deadChance or 0.2
	local minExitDistance = opts.minExitDistance or 5
	local rng = makeRng(seed)
	local W, D = layout.width, layout.depth
	local cells = layout.cells

	local function isProtected(x: number, z: number): boolean
		return protected[x * 1000 + z] == true
	end

	-- Union-find over cells.
	local parent: { [number]: number } = {}
	local function find(k: number): number
		while parent[k] ~= k do
			parent[k] = parent[parent[k]]
			k = parent[k]
		end
		return k
	end
	local function union(a: number, b: number): boolean
		local ra, rb = find(a), find(b)
		if ra == rb then
			return false
		end
		parent[ra] = rb
		return true
	end
	for x = 1, W do
		for z = 1, D do
			parent[x * 1000 + z] = x * 1000 + z
		end
	end

	-- Remember every inner wall so we can count what changed.
	local before: { [number]: boolean } = {}
	for x = 1, W do
		for z = 1, D do
			before[(x * 1000 + z) * 2] = cells[x][z].wallEast
			before[(x * 1000 + z) * 2 + 1] = cells[x][z].wallSouth
		end
	end

	-- Sort walls into "kept" (touch a protected cell) and "free" (re-rolled).
	local free = {}
	for x = 1, W do
		for z = 1, D do
			for _, d in { { 1, 0 }, { 0, 1 } } do
				local nx, nz = x + d[1], z + d[2]
				if nx <= W and nz <= D then
					if isProtected(x, z) or isProtected(nx, nz) then
						if not LevelGen.hasWall(layout, x, z, d[1], d[2]) then
							union(x * 1000 + z, nx * 1000 + nz)
						end
					else
						table.insert(free, { x, z, d[1], d[2] })
						setWall(layout, x, z, d[1], d[2], true)
					end
				end
			end
		end
	end

	-- Shuffle free walls, then open them Kruskal-style to join everything.
	for i = #free, 2, -1 do
		local j = rng.int(1, i)
		free[i], free[j] = free[j], free[i]
	end
	for _, w in free do
		local x, z, dx, dz = w[1], w[2], w[3], w[4]
		if union(x * 1000 + z, (x + dx) * 1000 + (z + dz)) then
			setWall(layout, x, z, dx, dz, false)
		elseif rng.float() < loopChance then
			setWall(layout, x, z, dx, dz, false)
		end
	end

	-- Rooms: forget rooms that were rewired, open a couple of new ones in
	-- fully unprotected space.
	local keptRooms = {}
	for _, room in layout.rooms do
		local touched = false
		for x = room.x, room.x + room.w - 1 do
			for z = room.z, room.z + room.d - 1 do
				if not isProtected(x, z) then
					touched = true
				end
			end
		end
		if touched then
			for x = room.x, room.x + room.w - 1 do
				for z = room.z, room.z + room.d - 1 do
					if not isProtected(x, z) then
						cells[x][z].room = nil
					end
				end
			end
			-- Partly protected rooms stay listed so pillars next to players
			-- survive; the builder only places a pillar where all four
			-- surrounding cells are still room cells.
			for x = room.x, room.x + room.w - 1 do
				for z = room.z, room.z + room.d - 1 do
					if isProtected(x, z) then
						table.insert(keptRooms, room)
						break
					end
				end
				if keptRooms[#keptRooms] == room then
					break
				end
			end
		else
			table.insert(keptRooms, room)
		end
	end
	layout.rooms = keptRooms
	for _ = 1, newRooms do
		for _attempt = 1, 12 do
			local w, d = rng.int(2, 4), rng.int(2, 4)
			local rx, rz = rng.int(1, W - w + 1), rng.int(1, D - d + 1)
			local clear = true
			for x = rx, rx + w - 1 do
				for z = rz, rz + d - 1 do
					if isProtected(x, z) or cells[x][z].room then
						clear = false
					end
				end
			end
			if clear then
				local id = #layout.rooms + 1
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
				break
			end
		end
	end

	-- New light pattern everywhere that changed.
	for x = 1, W do
		for z = 1, D do
			if not isProtected(x, z) then
				local roll = rng.float()
				cells[x][z].light = if roll < deadChance
					then "dead"
					elseif roll < deadChance + flickerChance then "flicker"
					else "on"
			end
		end
	end

	-- Move the lift, unless someone is near it.
	if not isProtected(layout.exit.x, layout.exit.z) then
		-- Distance from the nearest protected cell, by walking.
		local nearest: { [number]: number } = {}
		local queue = {}
		for k in protected do
			nearest[k] = 0
			table.insert(queue, { k // 1000, k % 1000 })
		end
		local head = 1
		while head <= #queue do
			local x, z = queue[head][1], queue[head][2]
			head += 1
			for _, d in DIRS do
				local nx, nz = x + d[1], z + d[2]
				local k = nx * 1000 + nz
				if inBounds(layout, nx, nz) and nearest[k] == nil and not LevelGen.hasWall(layout, x, z, d[1], d[2]) then
					nearest[k] = nearest[x * 1000 + z] + 1
					table.insert(queue, { nx, nz })
				end
			end
		end
		local options_ = {}
		for x = 1, W do
			for z = 1, D do
				local dist = nearest[x * 1000 + z]
				if dist and dist >= minExitDistance and not (x == layout.spawn.x and z == layout.spawn.z) then
					table.insert(options_, { x = x, z = z })
				end
			end
		end
		if #options_ > 0 then
			layout.exit = options_[rng.int(1, #options_)]
		end
	end
	cells[layout.exit.x][layout.exit.z].light = "on"

	local changed = 0
	for x = 1, W do
		for z = 1, D do
			if before[(x * 1000 + z) * 2] ~= cells[x][z].wallEast then
				changed += 1
			end
			if before[(x * 1000 + z) * 2 + 1] ~= cells[x][z].wallSouth then
				changed += 1
			end
		end
	end
	return changed
end

return LevelGen
