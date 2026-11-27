--!strict
-- Crew rules as pure functions, so they can be tested offline.

local Crews = {}

-- Which crew a new player joins: the emptiest one that has room
-- (ties go to the lowest number). nil if every crew is full.
function Crews.pick(counts: { number }, crewCount: number, crewSize: number): number?
	local best: number? = nil
	for c = 1, crewCount do
		local n = counts[c] or 0
		if n < crewSize and (best == nil or n < (counts[best] or 0)) then
			best = c
		end
	end
	return best
end

-- The crew quota for a sublevel: scales with crew size and grows with
-- depth. Rounded to $10.
function Crews.quota(depth: number, members: number, solo: number, perExtra: number, growth: number): number
	local base = solo + perExtra * math.max(0, members - 1)
	return math.floor(base * growth ^ math.max(0, depth - 1) / 10 + 0.5) * 10
end

-- How much more loot is worth at this depth (1.0 on sublevel 1).
function Crews.lootMultiplier(depth: number, perDepth: number): number
	return 1 + perDepth * math.max(0, depth - 1)
end

-- Level width/depth in cells for a crew of this size.
function Crews.levelSize(members: number, sizes: { number }): number
	return sizes[math.clamp(members, 1, #sizes)]
end

-- Cash each member takes home when a sublevel is cleared: the whole bank,
-- split evenly (dead members included: it's a crew).
function Crews.split(banked: number, members: number): number
	return if members > 0 then math.floor(banked / members) else 0
end

return Crews
