-- Game tuning numbers in one place. All first guesses: change them
-- after playtests. Shared so the HUD can read them too.
return {
	-- SUBLEVELS. Each crew gets its own level. Meet the crew quota, get
	-- everyone alive into the lift, then go deeper (bigger quota, better
	-- loot, more danger) or return to the safehouse. Run out of time, or
	-- all die, and the crew is wiped.
	SUBLEVEL_SECONDS = 480, -- time to meet the quota and get everyone in the lift
	QUOTA_SOLO = 250, -- sublevel 1 quota for a crew of one
	QUOTA_PER_EXTRA = 100, -- + this per extra crew member (crew of 4: 550)
	QUOTA_GROWTH = 1.35, -- each sublevel deeper multiplies the quota by this
	LOOT_VALUE_PER_DEPTH = 0.2, -- loot is worth +20% per sublevel deeper (x1.0, x1.2, x1.4 ...)
	ARTEFACTS_PER_100_CELLS = 8, -- how much loot a level holds (a 30x30 level: 72)
	LEVEL_SIZE_BY_CREW = { 30, 30, 32, 32 }, -- level width/depth in cells for crews of 1-4 (Jason: at least 30x30)
	LEVEL_SPACING = 4000, -- studs between crews' levels (keeps them out of each other's streaming range)
	DESCENT_COUNTDOWN = 5, -- seconds after a crew is all Ready (or chooses Deeper) before the lift drops
	WIPE_LOSES_KIT = true, -- a wiped crew loses everything bought in the shop (Cash is kept)
	-- Danger by depth (sublevel number).
	DEPTH = {
		lampjawFrom = 2, -- Lampjaw starts haunting the lights from this sublevel
		tenantAtStartFrom = 3, -- from here the Tenant is in the level from the start, not after the first Shift
		secondTenantFrom = 4, -- a second Tenant from here
		tenantSpeedPerDepth = 0.4, -- chase speed + this per sublevel after the first...
		tenantSpeedCap = 24.5, -- ...but never as fast as a sprint (25.6)
		shiftFasterPerDepth = 0.07, -- Shifts come this much more often per sublevel...
		shiftMinScale = 0.55, -- ...down to this fraction of the normal gap
	},
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

	-- THE TENANT: hunts by sound. Arrives right after the first Shift (from
	-- the start deeper down, see DEPTH) and re-appears near the loudest
	-- player after every Shift. Counter: stay
	-- quiet, split up, hide in the exit lift.
	TENANT = {
		enabled = true,
		height = 9.5, -- studs (ceiling is 11)
		-- Speeds (studs/s). You walk at 16 and sprint at 25.6 until stamina
		-- runs out (about 5.5 s from full). It chases faster than you walk,
		-- a little slower than you sprint: you can just about pull away, but
		-- it stays close, and when your stamina goes it gains fast. Break
		-- line of sight and go quiet to lose it.
		wanderSpeed = 6,
		investigateSpeed = 12, -- heading to a noise
		chaseSpeed = 21.5,
		noticeSeconds = 1.6, -- when it spots you it stops and shrieks this long before it chases
		killRange = 4, -- studs: caught
		sightRange = 45, -- studs: will chase what it can see this close
		-- Hearing: how far away each sound reaches it, in studs (a cell is
		-- 20, a level is ~600 across). Nothing carries across the map.
		hearWalk = 16, -- walking: only right next to it
		hearSprint = 50, -- sprinting: a couple of cells
		hearPerWeight = 0.6, -- extra studs per point of carried weight (rattling loot)
		hearDrop = 75, -- dropping loot: the loudest thing you can do
		forgetAfter = 8, -- seconds without hearing or seeing you before it gives up
		arriveMinCells = 4, -- after a Shift it appears at least this many cells (by path) from everyone
		arriveMaxCells = 7, -- ...and at most this far from the loudest player
		killCooldown = 6, -- seconds it lingers after taking someone
		arriveGraceSeconds = 6, -- after it arrives it can't take anyone for this long
		firstRunChaseScale = 0.95, -- run 1 only: chase speed x this (21.5 -> ~20.4)
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

	-- Flashlight (shop item)
	FLASHLIGHT_SECONDS = 150, -- battery life per run
	FLASHLIGHT_RANGE = 40,
	FLASHLIGHT_BRIGHTNESS = 2.2,
	SOFTBOOTS_NOISE = 0.6, -- soft-sole boots multiply your noise radius by this

	-- Monetisation hooks. Every ID is 0 = switched off: nothing is sold and
	-- no buy prompts appear. Jason creates the real passes/products on the
	-- Creator Hub and pastes the IDs here (see TODO.md). Cosmetic and
	-- crew-helping only: nothing that lets a paying player out-earn others.
	MONETISATION = {
		SUIT_COLOURS_PASS = 0, -- game pass: choose your crew suit colour at the safehouse wardrobe
		SUPPORTER_PASS = 0, -- game pass: amber "SUPPORTER" stripe on your suit's patch
		CREW_SUPPLY_PRODUCT = 0, -- developer product: energy drink + soft boots for your whole crew next run
	},
	SUIT_COLOURS = {
		Color3.fromRGB(58, 92, 88), -- oxidised teal (everyone's default)
		Color3.fromRGB(150, 70, 40), -- rust orange
		Color3.fromRGB(70, 74, 82), -- gunmetal
		Color3.fromRGB(120, 112, 70), -- faded olive
		Color3.fromRGB(150, 140, 120), -- dust white
	},

	-- The Shift
	SHIFT_MIN_SECONDS = 80, -- time between Shifts is random in this range
	SHIFT_MAX_SECONDS = 120,
	SHIFT_WARNING_SECONDS = 5, -- hum rises, lights stutter
	SHIFT_BLACKOUT_SECONDS = 3, -- total darkness while the maze rewires
	SHIFT_SAFE_RADIUS = 0, -- 0 = only the cell you stand in keeps its walls; 1 = 3x3 (too safe: changes happened out of sight)
	SHIFT_NOT_BEFORE_END = 25, -- no Shift this close to the end of a run

	-- Texture and sound IDs live in AssetIds.luau (written by tools/upload_assets.py).
}
