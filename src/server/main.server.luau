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
local ShiftService = require(script.Parent:WaitForChild("ShiftService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local Uniform = require(script.Parent:WaitForChild("Uniform"))
local Tenant = require(script.Parent:WaitForChild("Tenant"))
local Lampjaw = require(script.Parent:WaitForChild("Lampjaw"))
local MapService = require(script.Parent:WaitForChild("MapService"))

-- Dark, hazy, sickly-yellow lighting. See Atmosphere.luau to tweak the look.
Atmosphere.apply()

-- Nobody spawns until the level (and its lights) exist. Spawning into an
-- unbuilt level, then being teleported in, left players in the dark for
-- the first few seconds while the lighting caught up.
Players.CharacterAutoLoads = false

-- Everyone wears the SHIFT crew suit, not their own avatar.
Uniform.init()

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
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	-- Normally you already spawn on the level's SpawnLocation; only move
	-- people who are somewhere else (e.g. after the level was rebuilt).
	if root and (root.Position - spawnCFrame().Position).Magnitude > 12 then
		character:PivotTo(spawnCFrame())
	end
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

	-- Invisible spawn pad in the start cell, so characters appear inside
	-- the lit level instead of being teleported in.
	local spawnPad = Instance.new("SpawnLocation")
	spawnPad.Name = "LevelSpawn"
	spawnPad.Anchored = true
	spawnPad.CanCollide = false
	spawnPad.CanTouch = false
	spawnPad.Transparency = 1
	spawnPad.Size = Vector3.new(6, 0.2, 6)
	spawnPad.Position = LevelBuilder.cellCenter(layout.spawn.x, layout.spawn.z) + Vector3.new(0, 0.1, 0)
	spawnPad.Neutral = true
	spawnPad.Duration = 0 -- no spawn forcefield bubble
	spawnPad.Parent = currentLevel
	local function placeLift(l: LevelGen.Layout): Vector3
		local old = (currentLevel :: Model):FindFirstChild("ExitLift")
		if old then
			old:Destroy()
		end
		return ExitLift.build(LevelBuilder.cellCenter(l.exit.x, l.exit.z), LevelBuilder.HEIGHT, currentLevel :: Model)
	end
	local lift = placeLift(layout)
	ShiftService.setLevel(layout, currentLevel :: Model, function(l)
		RunManager.setLift(placeLift(l))
		Remotes.Notify:FireAllClients("The lift has moved. Follow the compass.", "warn")
	end)
	Tenant.setLevel(layout)
	Lampjaw.setLevel(layout)
	MapService.setLevel(layout)
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
ShiftService.init()
Tenant.init()
Lampjaw.init()
MapService.init()
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

-- Level is built and lit: now let people spawn.
Players.CharacterAutoLoads = true
for _, player in Players:GetPlayers() do
	if not player.Character then
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
end

workspace:GetAttributeChangedSignal("LevelSeed"):Connect(function()
	local seed = workspace:GetAttribute("LevelSeed")
	if typeof(seed) == "number" then
		buildLevel(seed)
	end
end)
