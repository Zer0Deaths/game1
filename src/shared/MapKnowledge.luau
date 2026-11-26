--!strict
-- What the crew has SEEN of the maze, for the shared map. Pure data so it
-- can be tested offline. Each known cell stores which of its four sides had
-- a wall when someone last looked, and which Shift that was. After a Shift
-- the map is still drawn, but cells seen before it are marked stale: the
-- maze may have rebuilt there.

-- (The second form is for the offline tests, which run outside Roblox.)
local LevelGen = if script then require(script.Parent:WaitForChild("LevelGen")) else (require :: any)("./LevelGen")

local MapKnowledge = {}

-- Wall bits: 1 = east, 2 = south, 4 = west, 8 = north.
local SIDES = { { 1, 0, 1 }, { 0, 1, 2 }, { -1, 0, 4 }, { 0, -1, 8 } }

export type Entry = { key: number, mask: number, shift: number }
export type Knowledge = { [number]: Entry }

function MapKnowledge.maskOf(layout: LevelGen.Layout, x: number, z: number): number
	local mask = 0
	for _, s in SIDES do
		if LevelGen.hasWall(layout, x, z, s[1], s[2]) then
			mask += s[3]
		end
	end
	return mask
end

-- Someone standing in (cx, cz) sees their cell and looks down every open
-- corridor up to `range` cells. Returns the entries that are new or changed.
function MapKnowledge.reveal(knowledge: Knowledge, layout: LevelGen.Layout, cx: number, cz: number, shift: number, range: number): { Entry }
	local changed: { Entry } = {}
	local function see(x: number, z: number)
		local key = x * 1000 + z
		local mask = MapKnowledge.maskOf(layout, x, z)
		local old = knowledge[key]
		if not old or old.mask ~= mask or old.shift ~= shift then
			local entry = { key = key, mask = mask, shift = shift }
			knowledge[key] = entry
			table.insert(changed, entry)
		end
	end
	see(cx, cz)
	for _, s in SIDES do
		local x, z = cx, cz
		for _ = 1, range do
			if LevelGen.hasWall(layout, x, z, s[1], s[2]) then
				break
			end
			x += s[1]
			z += s[2]
			see(x, z)
		end
	end
	return changed
end

return MapKnowledge
