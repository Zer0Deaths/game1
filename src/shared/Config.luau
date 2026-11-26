-- Game tuning numbers in one place. All first guesses: change them
-- after playtests. Shared so the HUD can read them too.
return {
	RUN_SECONDS = 360, -- length of one run (MVP: 6 min; design target 15-20)
	BASE_QUOTA = 300, -- money needed in the first run
	QUOTA_GROWTH = 1.4, -- each met quota multiplies the next one by this
	ARTEFACT_COUNT = 26, -- artefacts scattered per level
	MAX_CARRY = 4, -- artefacts one player can hold at once
	WALK_SPEED = 16, -- Roblox default
	MIN_WALK_SPEED = 6, -- slowest you can get from carrying heavy loot
	SPEED_PER_WEIGHT = 1.1, -- studs/s lost per point of carried weight
	JUMP_HEIGHT = 7.2, -- Roblox default
	MIN_JUMP_HEIGHT = 2.5, -- fully loaded you can barely hop
	JUMP_PER_WEIGHT = 0.35,

	-- Sprint (Left Shift). Stamina runs 0..100.
	SPRINT_MULTIPLIER = 1.6,
	STAMINA_DRAIN = 18, -- per second while sprinting, empty-handed
	STAMINA_DRAIN_PER_WEIGHT = 3, -- extra drain per point of weight
	STAMINA_REGEN = 22, -- per second while not sprinting, empty-handed
	STAMINA_REGEN_PER_WEIGHT = 0.08, -- regen is divided by (1 + weight * this)
	STAMINA_REGEN_DELAY = 0.8, -- pause after sprinting before regen starts
	EXHAUSTED_UNTIL = 30, -- run dry and you can't sprint again until this
	LIFT_RADIUS = 6, -- how close to the lift centre counts as "inside"
	INTERMISSION_SECONDS = 8, -- pause between runs to show the result

	-- Lighting. Roblox takes ~15 s after joining before the ceiling lights
	-- actually light the walls, so each player starts with a brighter warm
	-- ambient that fades down to AMBIENT once the lights have caught up.
	AMBIENT = Color3.fromRGB(46, 41, 24), -- base light where no lamp reaches (was 28,25,14: too dark)
	START_AMBIENT = Color3.fromRGB(125, 112, 70), -- on join, until the lamps kick in
	START_AMBIENT_HOLD = 12, -- seconds at full START_AMBIENT
	START_AMBIENT_FADE = 8, -- seconds to fade down to AMBIENT

	-- The Shift
	SHIFT_MIN_SECONDS = 80, -- time between Shifts is random in this range
	SHIFT_MAX_SECONDS = 120,
	SHIFT_WARNING_SECONDS = 5, -- hum rises, lights stutter
	SHIFT_BLACKOUT_SECONDS = 3, -- total darkness while the maze rewires
	SHIFT_SAFE_RADIUS = 0, -- 0 = only the cell you stand in keeps its walls; 1 = 3x3 (too safe: changes happened out of sight)
	SHIFT_NOT_BEFORE_END = 25, -- no Shift this close to the end of a run
}
