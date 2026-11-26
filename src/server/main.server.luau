-- Runs on the server. Synced to ServerScriptService.Server.main
-- Builds a fresh level when the server starts and drops players into it.
--
-- To test a specific layout in Studio: select Workspace, and in the
-- Properties window set the attribute "LevelSeed" to any number.
-- The level rebuilds instantly and everyone is moved to the spawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- WaitForChild instead of a dot: if Rojo is mid-sync, this waits instead of crashing.
local LevelGen = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LevelGen"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))

local Atmosphere = require(script.Parent:WaitForChild("Atmosphere"))
local ArtefactService = require(script.Parent:WaitForChild("ArtefactService"))
local ExitLift = require(script.Parent:WaitForChild("ExitLift"))
local RunManager = require(script.Parent:WaitForChild("RunManager"))

-- Dark, hazy, sickly-yellow lighting. See Atmosphere.luau to tweak the look.
Atmosphere.apply()

-- The default Baseplate and SpawnLocation would poke into the level.
-- This only removes them while the game runs; your saved place is untouched.
for _, name in { "Baseplate", "SpawnLocation" } do
	local thing = workspace:FindFirstChild(name)
	if thing then
		thing:Destroy()
	end
end

local currentLevel: Model? = nil
local currentLayout: LevelGen.Layout? = nil

local function spawnCFrame(): CFrame
	local layout = currentLayout
	local pos = if layout
		then LevelBuilder.cellCenter(layout.spawn.x, layout.spawn.z)
		else Vector3.zero
	return CFrame.new(pos + Vector3.new(0, 4, 0))
end

local function moveToSpawn(character: Model)
	character:WaitForChild("HumanoidRootPart", 5)
	if not character.Parent then
		character.AncestryChanged:Wait()
	end
	task.wait() -- let Roblox finish its own spawn placement first
	character:PivotTo(spawnCFrame())
end

local function buildLevel(seed: number)
	if currentLevel then
		currentLevel:Destroy()
	end
	local started = os.clock()
	currentLayout = LevelGen.generate(seed)
	local layout = currentLayout :: LevelGen.Layout
	currentLevel = LevelBuilder.build(layout, workspace)
	ArtefactService.spawnAll(layout, currentLevel :: Model, LevelBuilder.cellCenter)
	local lift = ExitLift.build(
		LevelBuilder.cellCenter(layout.exit.x, layout.exit.z),
		LevelBuilder.HEIGHT,
		currentLevel :: Model
	)
	local partCount = 0
	for _, d in (currentLevel :: Model):GetDescendants() do
		if d:IsA("BasePart") then
			partCount += 1
		end
	end
	print(`[Level] seed {seed}: {partCount} parts in {math.round((os.clock() - started) * 1000)} ms`)

	for _, player in Players:GetPlayers() do
		if player.Character then
			task.spawn(moveToSpawn, player.Character)
		end
	end
	RunManager.startRun(lift)
end

ArtefactService.init()
RunManager.init(function()
	-- Next run: brand new level. Setting the attribute triggers the rebuild below.
	workspace:SetAttribute("LevelSeed", math.random(1, 999999))
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(moveToSpawn)
end)
for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(moveToSpawn)
end

local startSeed = workspace:GetAttribute("LevelSeed")
if typeof(startSeed) ~= "number" then
	startSeed = math.random(1, 999999)
	workspace:SetAttribute("LevelSeed", startSeed)
end
buildLevel(startSeed :: number)

workspace:GetAttributeChangedSignal("LevelSeed"):Connect(function()
	local seed = workspace:GetAttribute("LevelSeed")
	if typeof(seed) == "number" then
		buildLevel(seed)
	end
end)
