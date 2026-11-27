--!strict
-- Everything the safehouse shop sells, bought with your own Cash.
--   permanent: kept forever (saved once saving is on); level = how many times
--              it can be upgraded
--   run:       used up at the end of the next run
--   melee:     a weapon in your hand, sold at the armoury in the exit lift.
--              One at a time (buying another swaps it). It breaks after
--              `uses` hits and is lost if you die or the crew is wiped.
--              Click (or R2) to swing. A hit stuns the Tenant for `stun`
--              seconds; a hit on Lampjaw's red light smashes it and drives
--              it out. Every swing is a noise (`noise` studs): the Tenant
--              hears it, and inside the Quiet's ring it gets you killed.
-- where: "safehouse" (the supplies counter, the default) or "lift" (the armoury).
-- Prices are first guesses: tune here.

export type Item = {
	id: string,
	name: string,
	description: string,
	price: { number }, -- price per level (permanent) or single price (run, melee)
	kind: "permanent" | "run" | "melee",
	where: ("safehouse" | "lift")?,
	melee: Melee?,
}

export type Melee = {
	stun: number, -- seconds a hit stuns the Tenant
	reach: number, -- studs from your head
	cooldown: number, -- seconds between swings
	uses: number, -- hits before it breaks
	noise: number, -- studs a swing carries (a hit is half as loud again)
}

local ShopItems: { Item } = {
	{
		id = "flashlight",
		name = "Flashlight",
		description = "A head torch. F to switch on. The battery recharges in the safehouse.",
		price = { 150 },
		kind = "permanent",
	},
	{
		id = "bigpack",
		name = "Bigger pack",
		description = "Carry one more artefact. Buy twice for two more.",
		price = { 250, 450 },
		kind = "permanent",
	},
	{
		id = "softboots",
		name = "Soft-sole boots",
		description = "Next run: your footsteps carry 40% less far. The Tenant hears you later.",
		price = { 60 },
		kind = "run",
	},
	{
		id = "energydrink",
		name = "Energy drink",
		description = "Next run: stamina comes back 50% faster.",
		price = { 40 },
		kind = "run",
	},
	{
		id = "melee_pipe",
		name = "Lead pipe",
		description = "Cheap and quick. Stuns the Tenant 2.5 s. 4 hits before it bends.",
		price = { 90 },
		kind = "melee",
		where = "lift",
		melee = { stun = 2.5, reach = 6, cooldown = 0.8, uses = 4, noise = 26 },
	},
	{
		id = "melee_crowbar",
		name = "Crowbar",
		description = "Fast and tough. Stuns the Tenant 3.5 s. 7 hits.",
		price = { 180 },
		kind = "melee",
		where = "lift",
		melee = { stun = 3.5, reach = 6.5, cooldown = 0.75, uses = 7, noise = 30 },
	},
	{
		id = "melee_axe",
		name = "Fire axe",
		description = "Long reach, slow swing. Stuns the Tenant 5 s. 5 hits.",
		price = { 320 },
		kind = "melee",
		where = "lift",
		melee = { stun = 5, reach = 7.5, cooldown = 1.2, uses = 5, noise = 38 },
	},
	{
		id = "melee_sledge",
		name = "Sledgehammer",
		description = "Very slow, very loud. Stuns the Tenant 6.5 s. 8 hits.",
		price = { 450 },
		kind = "melee",
		where = "lift",
		melee = { stun = 6.5, reach = 7, cooldown = 1.7, uses = 8, noise = 55 },
	},
}

return ShopItems
