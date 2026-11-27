--!strict
-- ShiftService: THE SHIFT, the game's signature mechanic. One per crew
-- level (Sublevels creates them).
--
-- Every 80-120 s (Config; sooner deeper down):
--   1. Warning (5 s): the crew's ShiftWarning = true. Clients make the hum
--      rise and the lights stutter.
--   2. Blackout (3 s): Shifting = true. Clients kill every ceiling light
--      and the compass spins. Meanwhile the server rewires every part of
--      the maze that isn't next to a player (LevelGen.shift), rebuilds
--      the walls, and may move the exit lift.
--   3. Lights come back on a different maze.
--
-- State lives on the crew's CrewState folder (ShiftWarning, Shifting,
-- ShiftCount). Server-authoritative: clients only do lights and sound.
-- No camera effects at all.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local ArtefactService = require(script.Parent:WaitForChild("ArtefactService"))

local ShiftService = {}

export type Shift = {
	force: () -> (),
	destroy: () -> (),
}

local function now(): number
	return workspace:GetServerTimeNow()
end

-- ctx: the crew level (Sublevels). exitMoved is called when the lift moves.
function ShiftService.create(ctx: any, exitMoved: (LevelGen.Layout) -> ()): Shift
	local state: Folder = ctx.state
	local alive = true
	local shifting = false
	local nextShiftAt = math.huge
	local D = Config.DEPTH
	local gapScale = math.max(D.shiftMinScale, 1 - D.shiftFasterPerDepth * (ctx.depth - 1))

	local function scheduleNext()
		nextShiftAt = now() + (Config.SHIFT_MIN_SECONDS + math.random() * (Config.SHIFT_MAX_SECONDS - Config.SHIFT_MIN_SECONDS)) * gapScale
	end

	state:SetAttribute("ShiftWarning", false)
	state:SetAttribute("Shifting", false)
	state:SetAttribute("ShiftCount", 0)
	scheduleNext()

	-- Cells that must not change: every cell within SAFE_RADIUS of a living player.
	local function protectedCells(current: LevelGen.Layout): { [number]: boolean }
		local protected: { [number]: boolean } = {}
		local r = Config.SHIFT_SAFE_RADIUS
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 and LevelBuilder.inLevel(current, root.Position, ctx.origin) then
				local cx, cz = LevelBuilder.cellOf(current, root.Position, ctx.origin)
				for dx = -r, r do
					for dz = -r, r do
						local x, z = cx + dx, cz + dz
						if x >= 1 and x <= current.width and z >= 1 and z <= current.depth then
							protected[x * 1000 + z] = true
						end
					end
				end
			end
		end
		return protected
	end

	local function doShift()
		local current, model = ctx.layout, ctx.model
		if not alive or shifting then
			return
		end
		shifting = true

		-- 1. Warning.
		state:SetAttribute("ShiftWarning", true)
		ctx.notify("The hum is rising...", "warn")
		task.wait(Config.SHIFT_WARNING_SECONDS)
		if not alive or state:GetAttribute("State") ~= "playing" then
			state:SetAttribute("ShiftWarning", false)
			shifting = false
			return
		end

		-- 2. Blackout and rewire.
		state:SetAttribute("ShiftWarning", false)
		state:SetAttribute("Shifting", true)
		task.wait(0.4) -- let clients go dark before anything moves
		if not alive then
			return
		end

		local started = os.clock()
		local oldExit = current.exit
		local lootBefore = if ctx.artefacts then #ctx.artefacts:GetChildren() else 0
		local protected = protectedCells(current)
		local protectedCount = 0
		for _ in protected do
			protectedCount += 1
		end
		local changed = LevelGen.shift(current, protected, math.random(1, 2 ^ 30))
		LevelBuilder.buildStructure(current, model)
		local moved = current.exit.x ~= oldExit.x or current.exit.z ~= oldExit.z
		if moved then
			exitMoved(current)
		end
		local count = ((state:GetAttribute("ShiftCount") or 0) :: number) + 1
		state:SetAttribute("ShiftCount", count)
		print(
			`[Shift] crew {ctx.crew} #{count}: {changed} walls changed, {protectedCount} of {current.width * current.depth} cells protected, `
				.. `lift {if moved then "moved" else "stayed"}, rebuilt in {math.round((os.clock() - started) * 1000)} ms`
		)

		-- Loot survives the Shift: anything the new walls, props or lift
		-- landed on is moved to the nearest clear spot. Carried loot is in
		-- players' hands and backpacks, which the rebuild never touches.
		task.wait() -- let the new parts register for spatial queries
		local folder: Instance? = ctx.artefacts
		if alive and folder and folder.Parent then
			local blockers = {}
			for _, b in { model:FindFirstChild("Structure"), ctx.liftModel } do
				if b then
					table.insert(blockers, b)
				end
			end
			local ok, onFloor, shifted, stuck = pcall(ArtefactService.resettle, folder, current, ctx.origin, blockers)
			local carried = 0
			for _, p in Players:GetPlayers() do
				if p:GetAttribute("Crew") == ctx.crew then
					carried += #ArtefactService.carried(p)
				end
			end
			if ok then
				print(`[Shift] crew {ctx.crew} #{count} loot: {lootBefore} on the floor before, {onFloor} after ({shifted} moved out of new walls/props, {stuck} stuck), {carried} carried`)
			else
				warn(`[Shift] loot check failed: {onFloor}`)
			end
		end

		task.wait(math.max(0, Config.SHIFT_BLACKOUT_SECONDS - 0.4 - (os.clock() - started)))

		-- 3. Lights back on a different maze.
		if alive then
			state:SetAttribute("Shifting", false)
		end
		shifting = false
		scheduleNext()
	end

	task.spawn(function()
		while alive do
			task.wait(0.5)
			if not alive or state:GetAttribute("State") ~= "playing" or shifting then
				continue
			end
			local endsAt = (state:GetAttribute("EndsAt") or math.huge) :: number
			if now() >= nextShiftAt then
				if endsAt - now() > Config.SHIFT_NOT_BEFORE_END then
					task.spawn(doShift)
				else
					nextShiftAt = math.huge -- too close to the end of this sublevel
				end
			end
		end
	end)

	return {
		force = function()
			task.spawn(doShift)
		end,
		destroy = function()
			alive = false
			state:SetAttribute("ShiftWarning", false)
			state:SetAttribute("Shifting", false)
		end,
	}
end

return ShiftService
