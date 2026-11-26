--!strict
-- Everything the safehouse shop sells, bought with your own Cash.
--   permanent: kept forever (saved once saving is on); level = how many times
--              it can be upgraded
--   run:       used up at the end of the next run
-- Prices are first guesses: tune here.

export type Item = {
	id: string,
	name: string,
	description: string,
	price: { number }, -- price per level (permanent) or single price (run)
	kind: "permanent" | "run",
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
}

return ShopItems
