--!strict
-- Artefact types: the junk worth money inside the levels.
-- Heavier items are worth more but slow you down (see Config).
-- Grey-box visuals: one part each, built-in materials only.

export type ArtefactDef = {
	id: string,
	name: string,
	minValue: number,
	maxValue: number,
	weight: number,
	size: Vector3,
	shape: Enum.PartType,
	color: Color3,
	material: Enum.Material,
	rarity: number, -- relative spawn chance
}

local Artefacts: { ArtefactDef } = {
	{
		id = "pager", name = "Dead Pager", minValue = 8, maxValue = 18, weight = 0.5,
		size = Vector3.new(0.8, 0.4, 1.2), shape = Enum.PartType.Block,
		color = Color3.fromRGB(40, 40, 44), material = Enum.Material.Plastic, rarity = 10,
	},
	{
		id = "stapler", name = "Rusted Stapler", minValue = 10, maxValue = 22, weight = 0.5,
		size = Vector3.new(0.6, 0.6, 1.6), shape = Enum.PartType.Block,
		color = Color3.fromRGB(110, 40, 36), material = Enum.Material.CorrodedMetal, rarity = 10,
	},
	{
		id = "reel", name = "Film Reel", minValue = 20, maxValue = 40, weight = 1,
		size = Vector3.new(0.4, 1.6, 1.6), shape = Enum.PartType.Cylinder,
		color = Color3.fromRGB(120, 120, 126), material = Enum.Material.Metal, rarity = 8,
	},
	{
		id = "phone", name = "Rotary Phone", minValue = 30, maxValue = 55, weight = 1.5,
		size = Vector3.new(1.4, 0.9, 1.2), shape = Enum.PartType.Block,
		color = Color3.fromRGB(150, 30, 30), material = Enum.Material.Plastic, rarity = 7,
	},
	{
		id = "fan", name = "Desk Fan", minValue = 40, maxValue = 70, weight = 2,
		size = Vector3.new(1.8, 1.8, 0.8), shape = Enum.PartType.Block,
		color = Color3.fromRGB(190, 190, 176), material = Enum.Material.Metal, rarity = 6,
	},
	{
		id = "cashbox", name = "Locked Cash Box", minValue = 60, maxValue = 110, weight = 3,
		size = Vector3.new(1.6, 0.9, 1.2), shape = Enum.PartType.Block,
		color = Color3.fromRGB(60, 80, 60), material = Enum.Material.DiamondPlate, rarity = 4,
	},
	{
		id = "typewriter", name = "Typewriter", minValue = 80, maxValue = 140, weight = 4,
		size = Vector3.new(2, 1, 1.6), shape = Enum.PartType.Block,
		color = Color3.fromRGB(30, 34, 30), material = Enum.Material.Metal, rarity = 3,
	},
	{
		id = "idol", name = "Humming Idol", minValue = 150, maxValue = 260, weight = 5,
		size = Vector3.new(1.2, 2.2, 1.2), shape = Enum.PartType.Block,
		color = Color3.fromRGB(196, 150, 60), material = Enum.Material.Foil, rarity = 1,
	},
}

return Artefacts
