--!strict
-- The kinds of level a descent can land in. Each one changes the generator
-- (rooms, loops, how many lights are broken), the colours and materials,
-- the light colour, and the haze. All original SHIFT locations.
--   unlockRun: first run number this level can appear on (runs count up
--              while at least one crew keeps meeting quota)
--   weight:    how likely it is once unlocked

export type LevelType = {
	id: string,
	name: string,
	blurb: string,
	unlockRun: number,
	weight: number,
	gen: {
		width: number?,
		depth: number?,
		loopChance: number?,
		roomCount: number?,
		atriumCount: number?,
		officeCount: number?,
		storageCount: number?,
		hallCount: number?,
		flickerChance: number?,
		deadChance: number?,
	},
	colours: { [string]: Color3 }, -- overrides LevelBuilder's palette keys
	materials: { [string]: string }, -- Enum.Material names for wall, carpet (floor), ceiling, trim
	variants: { [string]: string }, -- texture MaterialVariants for wall, carpet, ceiling (Materials.luau), used once uploaded
	light: Color3,
	haze: { colour: Color3, decay: Color3, density: number },
	tint: Color3,
}

-- Color3 outside Roblox (offline tests) is just a table.
local rgb: (number, number, number) -> Color3 = if Color3
	then Color3.fromRGB
	else function(r: number, g: number, b: number): Color3
		return { r, g, b } :: any
	end

local LevelTypes: { LevelType } = {
	{
		id = "carpet",
		name = "The Carpet",
		blurb = "Damp carpet, yellow walls, the hum.",
		unlockRun = 1,
		weight = 3,
		gen = {},
		colours = {},
		materials = {},
		variants = { wall = "SHIFT_Wallpaper", carpet = "SHIFT_Carpet", ceiling = "SHIFT_CeilingTile" },
		light = rgb(246, 242, 212),
		haze = { colour = rgb(150, 128, 70), decay = rgb(60, 46, 18), density = 0.42 },
		tint = rgb(255, 240, 200),
	},
	{
		id = "ward",
		name = "The Ward",
		blurb = "Tiled corridors, cold light, more of it broken.",
		unlockRun = 2,
		weight = 2,
		gen = { width = 28, depth = 28, loopChance = 0.1, roomCount = 4, atriumCount = 0, officeCount = 5, storageCount = 1, hallCount = 8, deadChance = 0.32, flickerChance = 0.14 },
		colours = {
			wall = rgb(196, 206, 200),
			skirting = rgb(90, 110, 104),
			carpet = rgb(150, 156, 150),
			ceiling = rgb(214, 218, 214),
			grid = rgb(160, 166, 164),
			pillar = rgb(180, 192, 186),
			lightOn = rgb(220, 236, 246),
		},
		materials = { wall = "Marble", carpet = "Slate", ceiling = "Plaster", trim = "SmoothPlastic" },
		variants = { ceiling = "SHIFT_CeilingTile" },
		light = rgb(220, 236, 246),
		haze = { colour = rgb(110, 130, 130), decay = rgb(30, 44, 46), density = 0.45 },
		tint = rgb(225, 240, 245),
	},
	{
		id = "plant",
		name = "The Plant Room",
		blurb = "Concrete, grating and sodium light. Lots of it flickers.",
		unlockRun = 3,
		weight = 2,
		gen = { width = 32, depth = 32, loopChance = 0.26, roomCount = 6, atriumCount = 2, officeCount = 1, storageCount = 6, hallCount = 3, flickerChance = 0.24, deadChance = 0.18 },
		colours = {
			wall = rgb(120, 116, 108),
			skirting = rgb(70, 66, 60),
			carpet = rgb(84, 82, 78),
			ceiling = rgb(92, 90, 86),
			grid = rgb(70, 68, 64),
			pillar = rgb(110, 106, 98),
			lightOn = rgb(255, 190, 120),
		},
		materials = { wall = "Concrete", carpet = "DiamondPlate", ceiling = "Concrete", trim = "Metal" },
		variants = { wall = "SHIFT_Concrete", ceiling = "SHIFT_Concrete" },
		light = rgb(255, 190, 120),
		haze = { colour = rgb(120, 90, 60), decay = rgb(50, 30, 14), density = 0.46 },
		tint = rgb(255, 226, 196),
	},
}

local byId: { [string]: LevelType } = {}
for _, t in LevelTypes do
	byId[t.id] = t
end

local M = {}
M.list = LevelTypes

function M.get(id: string): LevelType
	return byId[id] or LevelTypes[1]
end

-- Pick a level type for this run number with a 0..1 roll.
function M.pick(runNumber: number, roll: number): LevelType
	local total = 0
	for _, t in LevelTypes do
		if runNumber >= t.unlockRun then
			total += t.weight
		end
	end
	local target = roll * total
	for _, t in LevelTypes do
		if runNumber >= t.unlockRun then
			target -= t.weight
			if target < 0 then
				return t
			end
		end
	end
	return LevelTypes[1]
end

return M
