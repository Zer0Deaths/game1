-- Game tuning numbers in one place. All first guesses: change them
-- after playtests. Shared so the HUD can read them too.
return {
	RUN_SECONDS = 360, -- length of one run (MVP: 6 min; design target 15-20)
	BASE_QUOTA = 300, -- money needed in the first run
	QUOTA_GROWTH = 1.4, -- each met quota multiplies the next one by this
	ARTEFACT_COUNT = 26, -- artefacts scattered per level
	MAX_CARRY = 4, -- artefacts one player can hold at once
	WALK_SPEED = 16, -- Roblox default
	MIN_WALK_SPEED = 8, -- slowest you can get from carrying heavy loot
	SPEED_PER_WEIGHT = 0.7, -- studs/s lost per point of carried weight
	LIFT_RADIUS = 6, -- how close to the lift centre counts as "inside"
	INTERMISSION_SECONDS = 8, -- pause between runs to show the result
}
