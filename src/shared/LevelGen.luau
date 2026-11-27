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

-- kind: "room" (plain open area), "atrium" (big pillared hall),
-- "office" (desks and cabinets), "storage" (shelving), "hall" (a long,
-- straight, walled corridor). The builder dresses each kind differently.
export type Room = { x: number, z: number, w: number, d: number, kind: string }

export type Layout = {
	seed: number,
	width: number,
	depth: number,
	cells: { { Cell } }, -- cells[x][z]
	rooms: { Room },
	pieces: { [string]: number }?, -- how many of each set piece this level wants (the Shift keeps topping it up)
	spawn: { x: number, z: number },
	exit: { x: number, z: number }, -- exit lift, the reachable cell furthest from spawn
}

export type Options = {
	width: number?,
	depth: number?,
	loopChance: number?, -- extra walls knocked out after the maze, 0..1
	roomCount: number?,
	atriumCount: number?,
	officeCount: number?,
	storageCount: number?,
	hallCount: number?,
	flickerChance: number?,
	deadChance: number?,
	exitBand: { number }?, -- { lo, hi }: the lift is this fraction of the furthest walk from spawn (default 0.45-0.6)
	exitMin: number?, -- ...but never fewer cells than this (default 8)
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

-- Joins every cell into one connected maze by opening the fewest extra
-- walls (random ones, skipping any wall in `avoid` unless there is no
-- other way). Used after set pieces close walls.
local function connectAll(layout: Layout, rng: any, avoid: { [string]: boolean }, isProtected: (number, number) -> boolean)
	local W, D = layout.width, layout.depth
	local parent: { [number]: number } = {}
	local function find(k: number): number
		while parent[k] ~= k do
			parent[k] = parent[parent[k]]
			k = parent[k]
		end
		return k
	end
	for x = 1, W do
		for z = 1, D do
			parent[x * 1000 + z] = x * 1000 + z
		end
	end
	local closed, closedAvoid = {}, {}
	for x = 1, W do
		for z = 1, D do
			for _, d in { { 1, 0 }, { 0, 1 } } do
				local nx, nz = x + d[1], z + d[2]
				if nx <= W and nz <= D then
					local locked = isProtected(x, z) or isProtected(nx, nz)
					if LevelGen.hasWall(layout, x, z, d[1], d[2]) then
						if locked then
							continue -- walls by a player never change
						end
						local list = if avoid[`{x},{z},{d[1]},{d[2]}`] then closedAvoid else closed
						table.insert(list, { x, z, d[1], d[2] })
					else
						local a, b = find(x * 1000 + z), find(nx * 1000 + nz)
						if a ~= b then
							parent[a] = b
						end
					end
				end
			end
		end
	end
	for _, list in { closed, closedAvoid } do
		for i = #list, 2, -1 do
			local j = rng.int(1, i)
			list[i], list[j] = list[j], list[i]
		end
		for _, w in list do
			local a, b = find(w[1] * 1000 + w[2]), find((w[1] + w[3]) * 1000 + (w[2] + w[4]))
			if a ~= b then
				parent[a] = b
				setWall(layout, w[1], w[2], w[3], w[4], false)
			end
		end
	end
end

-- Halls are always lit: a long bright corridor is its own kind of wrong.
local function lightHalls(layout: Layout, rng: any, isProtected: (number, number) -> boolean)
	for _, room in layout.rooms do
		if room.kind == "hall" then
			for x = room.x, room.x + room.w - 1 do
				for z = room.z, room.z + room.d - 1 do
					if not isProtected(x, z) then
						layout.cells[x][z].light = if rng.float() < 0.15 then "flicker" else "on"
					end
				end
			end
		end
	end
end

-- Carves set pieces into the maze, biggest first so they find space, up
-- to `counts` of each kind (counting ones already there). Each is a
-- rectangle of cells with every inner wall removed; they never overlap
-- each other, the spawn cell, or any protected cell (or, for halls,
-- anything next to one, since a hall closes its side walls).
-- Afterwards the maze is reconnected without touching protected walls.
local function addSetPieces(layout: Layout, rng: any, counts: { [string]: number }, isProtected: (number, number) -> boolean)
	local cells = layout.cells
	local width, depth = layout.width, layout.depth
	local have: { [string]: number } = {}
	for _, room in layout.rooms do
		have[room.kind] = (have[room.kind] or 0) + 1
	end
	local function free(rx: number, rz: number, w: number, d: number, margin: number): boolean
		for x = rx - margin, rx + w - 1 + margin do
			for z = rz - margin, rz + d - 1 + margin do
				if inBounds(layout, x, z) then
					local inside = x >= rx and x < rx + w and z >= rz and z < rz + d
					if isProtected(x, z) then
						return false
					end
					if inside and (cells[x][z].room or (x == layout.spawn.x and z == layout.spawn.z)) then
						return false
					end
				end
			end
		end
		return true
	end
	local function place(kind: string, wMin: number, wMax: number, dMin: number, dMax: number, margin: number): Room?
		for _attempt = 1, 30 do
			local w, d = rng.int(wMin, wMax), rng.int(dMin, dMax)
			if w <= width and d <= depth then
				local rx, rz = rng.int(1, width - w + 1), rng.int(1, depth - d + 1)
				if free(rx, rz, w, d, margin) then
					local room: Room = { x = rx, z = rz, w = w, d = d, kind = kind }
					table.insert(layout.rooms, room)
					local id = #layout.rooms
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
					return room
				end
			end
		end
		return nil
	end
	local function want(kind: string): number
		return math.max(0, (counts[kind] or 0) - (have[kind] or 0))
	end
	for _ = 1, want("atrium") do
		place("atrium", 5, 7, 5, 7, 0)
	end
	-- Long halls: a straight corridor 7-13 cells long with solid sides,
	-- open at both ends and in one or two places along the way.
	local hallSides: { [string]: boolean } = {}
	for _ = 1, want("hall") do
		local along = rng.int(7, 13)
		local eastWest = rng.float() < 0.5
		local room = if eastWest then place("hall", along, along, 1, 1, 1) else place("hall", 1, 1, along, along, 1)
		if room then
			local openings = {}
			for _ = 1, rng.int(1, 2) do
				openings[rng.int(2, along - 1)] = if rng.float() < 0.5 then 1 else -1
			end
			for i = 1, along do
				local x = if eastWest then room.x + i - 1 else room.x
				local z = if eastWest then room.z else room.z + i - 1
				-- Sides: the two walls across the hall's direction.
				local sides = if eastWest then { { 0, 1 }, { 0, -1 } } else { { 1, 0 }, { -1, 0 } }
				for side, d in sides do
					local open = openings[i] == (if side == 1 then 1 else -1)
					setWall(layout, x, z, d[1], d[2], not open)
					hallSides[`{math.min(x, x + d[1])},{math.min(z, z + d[2])},{math.abs(d[1])},{math.abs(d[2])}`] = not open
				end
			end
			-- Both ends open into the maze.
			if eastWest then
				setWall(layout, room.x, room.z, -1, 0, false)
				setWall(layout, room.x + along - 1, room.z, 1, 0, false)
			else
				setWall(layout, room.x, room.z, 0, -1, false)
				setWall(layout, room.x, room.z + along - 1, 0, 1, false)
			end
		end
	end
	for _ = 1, want("storage") do
		place("storage", 3, 5, 2, 3, 0)
	end
	for _ = 1, want("office") do
		place("office", 3, 4, 3, 4, 0)
	end
	for _ = 1, want("room") do
		place("room", 2, 4, 2, 4, 0)
	end
	-- Closing hall sides can cut corners of the maze off: reconnect,
	-- preferring not to punch holes in the halls.
	connectAll(layout, rng, hallSides, isProtected)
end

function LevelGen.generate(seed: number, options: Options?): Layout
	local opts: Options = options or {} :: Options
	local width = opts.width or 30
	local depth = opts.depth or 30
	local loopChance = opts.loopChance or 0.18
	local roomCount = opts.roomCount or 8
	local atriumCount = opts.atriumCount or 1
	local officeCount = opts.officeCount or 3
	local storageCount = opts.storageCount or 2
	local hallCount = opts.hallCount or 4
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

	-- 4. Set pieces (atrium, halls, storage, offices, rooms).
	local pieces = {
		atrium = atriumCount,
		hall = hallCount,
		storage = storageCount,
		office = officeCount,
		room = roomCount,
	}
	layout.pieces = pieces
	addSetPieces(layout, rng, pieces, function()
		return false
	end)

	-- 5. Lights: most work, some flicker, some are dead (dark patches).
	-- Halls are always lit: a long bright corridor is its own kind of wrong.
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
	lightHalls(layout, rng, function()
		return false
	end)
	-- Spawn cell is always lit so players don't start blind.
	cells[1][1].light = "on"

	-- 6. Exit lift: a cell roughly half as far as the furthest one, so in a
	-- big level the walk is a trek, not a marathon. Lowest key wins ties so
	-- the same seed always picks the same cell.
	local dists = LevelGen.distancesFrom(layout, 1, 1)
	local maxDist = 0
	for _, dist in dists do
		maxDist = math.max(maxDist, dist)
	end
	local band = opts.exitBand or { 0.45, 0.6 }
	local floor_ = opts.exitMin or 8
	local lo, hi = math.max(floor_, math.floor(maxDist * band[1])), math.max(floor_, math.floor(maxDist * band[2]))
	local choices = {}
	for k, dist in dists do
		if dist >= lo and dist <= hi then
			table.insert(choices, k)
		end
	end
	table.sort(choices)
	local best = layout.exit
	if #choices > 0 then
		local k = choices[rng.int(1, #choices)]
		best = { x = k // 1000, z = k % 1000 }
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
	maxExitDistance: number?, -- ...and at most this many (early sublevels keep the lift close)
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
	local maxExitDistance = opts.maxExitDistance or math.huge
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
	-- Fresh set pieces in the rewired space, so the level keeps its halls,
	-- atriums and offices instead of melting into plain maze.
	local counts = layout.pieces or { room = newRooms }
	addSetPieces(layout, rng, counts, isProtected)

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

	lightHalls(layout, rng, isProtected)

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
				if dist and dist >= minExitDistance and dist <= maxExitDistance and not (x == layout.spawn.x and z == layout.spawn.z) then
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
