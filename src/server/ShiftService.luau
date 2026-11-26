--!strict
-- ShiftService: THE SHIFT, the game's signature mechanic.
--
-- Every 80-120 s (Config) during a run:
--   1. Warning (5 s): Workspace.ShiftWarning = true. Clients make the hum
--      rise and the lights stutter.
--   2. Blackout (3 s): Workspace.Shifting = true. Clients kill every
--      ceiling light and the compass spins. Meanwhile the server rewires
--      every part of the maze that isn't next to a player
--      (LevelGen.shift), rebuilds the walls and lights, and may move
--      the exit lift.
--   3. Lights come back on a different maze.
--
-- Server-authoritative: only the server decides the layout. Clients only
-- do the light and sound effects locally. No camera effects at all.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local ShiftService = {}

local layout: LevelGen.Layout? = nil
local levelModel: Model? = nil
local onExitMoved: ((LevelGen.Layout) -> ())? = nil
local nextShiftAt = math.huge
local shifting = false

local function now(): number
	return workspace:GetServerTimeNow()
end

local function scheduleNext()
	nextShiftAt = now() + Config.SHIFT_MIN_SECONDS + math.random() * (Config.SHIFT_MAX_SECONDS - Config.SHIFT_MIN_SECONDS)
end

-- Called by main whenever a fresh level is built (new run or new seed).
function ShiftService.setLevel(newLayout: LevelGen.Layout, model: Model, exitMoved: (LevelGen.Layout) -> ())
	layout = newLayout
	levelModel = model
	onExitMoved = exitMoved
	workspace:SetAttribute("ShiftWarning", false)
	workspace:SetAttribute("Shifting", false)
	workspace:SetAttribute("ShiftCount", 0)
	scheduleNext()
end

-- Cells that must not change: every cell within SAFE_RADIUS of a living player.
local function protectedCells(current: LevelGen.Layout): { [number]: boolean }
	local protected: { [number]: boolean } = {}
	local S = LevelBuilder.CELL
	local r = Config.SHIFT_SAFE_RADIUS
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local cx = math.clamp(math.floor(root.Position.X / S) + 1, 1, current.width)
			local cz = math.clamp(math.floor(root.Position.Z / S) + 1, 1, current.depth)
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
	local current, model = layout, levelModel
	if not current or not model or shifting then
		return
	end
	shifting = true

	-- 1. Warning.
	workspace:SetAttribute("ShiftWarning", true)
	Remotes.Notify:FireAllClients("The hum is rising...", "warn")
	task.wait(Config.SHIFT_WARNING_SECONDS)

	-- The run may have ended or the level been rebuilt during the warning.
	if layout ~= current or workspace:GetAttribute("RunState") ~= "playing" then
		workspace:SetAttribute("ShiftWarning", false)
		shifting = false
		return
	end

	-- 2. Blackout and rewire.
	workspace:SetAttribute("ShiftWarning", false)
	workspace:SetAttribute("Shifting", true)
	task.wait(0.4) -- let clients go dark before anything moves

	local started = os.clock()
	local oldExit = current.exit
	local protected = protectedCells(current)
	local protectedCount = 0
	for _ in protected do
		protectedCount += 1
	end
	local changed = LevelGen.shift(current, protected, math.random(1, 2 ^ 30))
	LevelBuilder.buildStructure(current, model)
	if current.exit.x ~= oldExit.x or current.exit.z ~= oldExit.z then
		if onExitMoved then
			onExitMoved(current)
		end
	end
	local count = (workspace:GetAttribute("ShiftCount") or 0) + 1
	workspace:SetAttribute("ShiftCount", count)
	print(
		`[Shift] #{count}: {changed} walls changed, {protectedCount} of {current.width * current.depth} cells protected, `
			.. `lift {if current.exit.x ~= oldExit.x or current.exit.z ~= oldExit.z then "moved" else "stayed"}, `
			.. `rebuilt in {math.round((os.clock() - started) * 1000)} ms`
	)

	task.wait(math.max(0, Config.SHIFT_BLACKOUT_SECONDS - 0.4 - (os.clock() - started)))

	-- 3. Lights back on a different maze.
	workspace:SetAttribute("Shifting", false)
	shifting = false
	scheduleNext()
end

function ShiftService.init()
	task.spawn(function()
		while true do
			task.wait(0.5)
			if workspace:GetAttribute("RunState") ~= "playing" or shifting then
				continue
			end
			local endsAt = workspace:GetAttribute("RunEndsAt") or math.huge
			if now() >= nextShiftAt then
				if endsAt - now() > Config.SHIFT_NOT_BEFORE_END then
					task.spawn(doShift)
				else
					nextShiftAt = math.huge -- too close to the end; wait for the next run
				end
			end
		end
	end)
end

-- For testing in Studio: set Workspace attribute "ForceShift" to true.
workspace:GetAttributeChangedSignal("ForceShift"):Connect(function()
	if workspace:GetAttribute("ForceShift") == true then
		workspace:SetAttribute("ForceShift", false)
		task.spawn(doShift)
	end
end)

return ShiftService
