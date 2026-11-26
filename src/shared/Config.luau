-- Game tuning numbers in one place. All first guesses: change them
-- after playtests. Shared so the HUD can read them too.
return {
	RUN_SECONDS = 360, -- length of one run (MVP: 6 min; design target 15-20)
	BASE_QUOTA = 300, -- money needed in the first run
	QUOTA_GROWTH = 1.4, -- each met quota multiplies the next one by this
	ARTEFACT_COUNT = 26, -- artefacts scattered per level
	MAX_CARRY = 4, -- artefacts one player can hold at once (the shop's bigger pack adds to this)
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

	-- First-person arms (Arms.client). Your real avatar arms are shown in
	-- first person and lifted forward at the shoulder so you can see them.
	-- The walk/run animation swings them; these angles are in degrees.
	SHOW_FIRST_PERSON_ARMS = false, -- off until a proper arms model exists (the avatar arms looked too big)
	ARMS = {
		idleRaise = 55, -- standing still: arms lowered, mostly out of view
		walkRaise = 88, -- walking: how far forward the arms lift
		sprintRaise = 100, -- sprinting: a bit higher, leaning into the run
		inward = 14, -- angle the arms in towards the centre
		lookFollow = 0.5, -- how much the arms follow looking up/down (0 = not at all)
		ease = 7, -- how quickly arms settle (higher = snappier)
	},

	-- THE TENANT: hunts by sound. Arrives right after the first Shift and
	-- re-appears near the loudest player after every Shift. Counter: stay
	-- quiet, split up, hide in the exit lift.
	TENANT = {
		enabled = true,
		height = 9.5, -- studs (ceiling is 11)
		wanderSpeed = 6, -- studs/s
		investigateSpeed = 11, -- heading to a noise
		chaseSpeed = 17.5, -- faster than walking (16), slower than sprinting (25.6)
		killRange = 4, -- studs: caught
		sightRange = 45, -- studs: will chase what it can see this close
		hearWalk = 40, -- studs: hears a walking player this far away
		hearSprint = 110, -- studs: hears a sprinting player this far away
		hearPerWeight = 2, -- extra studs per point of carried weight
		hearDrop = 90, -- studs: hears dropped loot this far away
		forgetAfter = 8, -- seconds without hearing or seeing you before it gives up
		arriveMinCells = 4, -- after a Shift it appears at least this many cells (by path) from everyone
		arriveMaxCells = 7, -- ...and at most this far from the loudest player
		killCooldown = 6, -- seconds it lingers after taking someone
	},

	-- LAMPJAW: lives in the flickering light fittings. It takes over one
	-- flickering light near a player (that light strobes red and buzzes);
	-- linger under it and it takes you. Counter: watch the lights, move fast.
	LAMPJAW = {
		enabled = true,
		reach = 6, -- studs from the centre of the light, measured flat
		grabAfter = 0.9, -- seconds under its light before it takes you (walking past is just safe; carrying loot isn't)
		grabAfterNearShift = 0.6, -- ...while the Shift warning is on
		holdMin = 12, -- seconds it stays in one light
		holdMax = 20,
		restMin = 8, -- seconds between lights
		restMax = 14,
		restNearShift = 3, -- much shorter rest while the Shift warning is on
		nearCells = 4, -- picks a flickering light within this many cells of someone
	},

	-- Shared map (M key): fills in wherever anyone on the server has looked.
	MAP_SIGHT_CELLS = 2, -- how far down an open corridor you "see" for the map
	MAP_UPDATE_SECONDS = 0.5,

	-- Crews: a 16-player server is split into up to 4 crews of 4. Each crew
	-- has its own quota and bank; everyone shares the same level.
	CREW_COUNT = 4,
	CREW_SIZE = 4,
	CREW_NAMES = { "Night Shift", "Graveyard", "Skeleton Crew", "Overtime" },
	CREW_COLOURS = {
		Color3.fromRGB(255, 196, 110), -- amber
		Color3.fromRGB(140, 200, 255), -- pale blue
		Color3.fromRGB(170, 230, 140), -- green
		Color3.fromRGB(240, 140, 200), -- pink
	},

	-- Safehouse hub: where crews wait, shop and pick crews between runs.
	HUB_ORIGIN = Vector3.new(-160, 0, 140), -- far from the level (which starts at 0,0)
	HUB_SECONDS = 60, -- countdown before the next descent
	HUB_ALL_READY_SECONDS = 5, -- countdown once everyone has pressed Ready

	-- Flashlight (shop item)
	FLASHLIGHT_SECONDS = 150, -- battery life per run
	FLASHLIGHT_RANGE = 40,
	FLASHLIGHT_BRIGHTNESS = 2.2,
	SOFTBOOTS_NOISE = 0.6, -- soft-sole boots multiply your noise radius by this

	-- The Shift
	SHIFT_MIN_SECONDS = 80, -- time between Shifts is random in this range
	SHIFT_MAX_SECONDS = 120,
	SHIFT_WARNING_SECONDS = 5, -- hum rises, lights stutter
	SHIFT_BLACKOUT_SECONDS = 3, -- total darkness while the maze rewires
	SHIFT_SAFE_RADIUS = 0, -- 0 = only the cell you stand in keeps its walls; 1 = 3x3 (too safe: changes happened out of sight)
	SHIFT_NOT_BEFORE_END = 25, -- no Shift this close to the end of a run
}
