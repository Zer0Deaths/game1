-- Runs on the server. Synced to ServerScriptService.Server.main
-- Builds a fresh level when the server starts and drops players into it.
--
-- To test a specific layout in Studio: select Workspace, and in the
-- Properties window set the attribute "LevelSeed" to any number.
-- The level rebuilds instantly and everyone is moved to the spawn.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelGen = require(ReplicatedStorage.Shared.LevelGen)
local LevelBuilder = require(script.Parent.LevelBuilder)

-- Dark, foggy, indoor lighting. Only the ceiling panels light the level.
Lighting.ClockTime = 0
Lighting.Brightness = 0
Lighting.Ambient = Color3.fromRGB(24, 22, 14)
Lighting.OutdoorAmbient = Color3.fromRGB(24, 22, 14)
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.FogColor = Color3.fromRGB(30, 27, 16)
Lighting.FogStart = 10
Lighting.FogEnd = 110

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
	currentLevel = LevelBuilder.build(currentLayout :: LevelGen.Layout, workspace)
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
end

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
