-- Runs on the server. Synced to ServerScriptService.Server.main
-- The game loop:
--   HUB      everyone is in the safehouse: pick a crew, shop, press Ready.
--            When all are ready (or the countdown ends) everyone descends.
--   PLAYING  a fresh level is built and every crew is dropped into it.
--            The dead go back to the safehouse until the next descent;
--            late joiners can use the descent lift to join in.
--   INTERMISSION  quotas are settled, then everyone returns to the hub.
--
-- Studio testing: set the Workspace attribute "LevelSeed" to a number while
-- in the hub to descend straight away into that exact layout.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- WaitForChild instead of a dot: if Rojo is mid-sync, this waits instead of crashing.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local LevelTypes = require(Shared:WaitForChild("LevelTypes"))
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
local CrewService = require(script.Parent:WaitForChild("CrewService"))
local Safehouse = require(script.Parent:WaitForChild("Safehouse"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MonetisationService = require(script.Parent:WaitForChild("MonetisationService"))

-- Dark, hazy, sickly-yellow lighting. See Atmosphere.luau to tweak the look.
Atmosphere.apply()

-- Nobody spawns until the safehouse exists.
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

local function now(): number
	return workspace:GetServerTimeNow()
end

local function levelSpawnCFrame(index: number): CFrame
	local layout = currentLayout
	local pos = if layout then LevelBuilder.cellCenter(layout.spawn.x, layout.spawn.z) else Vector3.zero
	-- Spread people around the start cell so nobody lands inside someone else.
	local angle = index * 2.4
	local r = 2 + (index % 4) * 1.5
	return CFrame.new(pos + Vector3.new(math.cos(angle) * r, 4, math.sin(angle) * r))
end

local function aliveRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end
	return nil
end

local function buildLevel(seed: number, levelType: LevelTypes.LevelType)
	if currentLevel then
		currentLevel:Destroy()
	end
	local started = os.clock()
	currentLayout = LevelGen.generate(seed, levelType.gen)
	local layout = currentLayout :: LevelGen.Layout
	LevelBuilder.setTheme(levelType.colours, levelType.materials)
	Atmosphere.applyTheme(levelType.haze, levelType.tint)
	workspace:SetAttribute("LevelType", levelType.id)
	workspace:SetAttribute("LevelName", levelType.name)
	workspace:SetAttribute("LightColour", levelType.light)
	currentLevel = LevelBuilder.build(layout, workspace)
	ArtefactService.spawnAll(layout, currentLevel :: Model, LevelBuilder.cellCenter)

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
	workspace:SetAttribute("LiftPosition", lift)
	print(`[Level] {levelType.name}, seed {seed}: built in {math.round((os.clock() - started) * 1000)} ms`)
	return lift
end

-- HUB -----------------------------------------------------------------------

local hub = Safehouse.build()

local function sendToHub(player: Player, index: number)
	local root = aliveRoot(player)
	if root then
		(player.Character :: Model):PivotTo(hub.arrivalCFrame(index))
	end
end

local function startHub()
	workspace:SetAttribute("RunState", "hub")
	workspace:SetAttribute("HubEndsAt", now() + Config.HUB_SECONDS)
	for i, player in Players:GetPlayers() do
		player:SetAttribute("Ready", false)
		player:SetAttribute("DiedThisRun", false)
		sendToHub(player, i)
	end
end

local descending = false
local seedFromStudio = false

local function descend(seed: number?)
	if descending then
		return
	end
	descending = true
	local chosen = seed or math.random(1, 999999)
	seedFromStudio = true
	workspace:SetAttribute("LevelSeed", chosen)
	seedFromStudio = false
	local nextRun = ((workspace:GetAttribute("RunNumber") or 0) :: number) + 1
	local levelType = LevelTypes.pick(nextRun, math.random())
	local lift = buildLevel(chosen, levelType)
	for i, player in Players:GetPlayers() do
		player:SetAttribute("Ready", false)
		player:SetAttribute("DiedThisRun", false)
		if aliveRoot(player) then
			(player.Character :: Model):PivotTo(levelSpawnCFrame(i))
		end
	end
	RunManager.startRun(lift)
	descending = false
end

-- Crew board.
for c, pr in hub.crewPrompts do
	pr.Triggered:Connect(function(player)
		if CrewService.switch(player, c) then
			Remotes.Notify:FireClient(player, `You joined {Config.CREW_NAMES[c]}.`, "money")
		elseif player:GetAttribute("Crew") ~= c then
			Remotes.Notify:FireClient(player, `{Config.CREW_NAMES[c]} is full.`, "warn")
		end
	end)
end

-- Shop counter: the shop UI lives on the client (Shop.client).
hub.shopPrompt.Triggered:Connect(function(player)
	Remotes.OpenShop:FireClient(player)
end)

-- Paid extras (switched off until IDs are set in Config.MONETISATION).
hub.wardrobePrompt.Triggered:Connect(MonetisationService.useWardrobe)
hub.supplyPrompt.Triggered:Connect(MonetisationService.promptSupplyDrop)

-- Descent lift: Ready in the hub, or join a run already under way.
hub.readyPrompt.Triggered:Connect(function(player)
	local state = workspace:GetAttribute("RunState")
	if state == "hub" then
		local ready = not player:GetAttribute("Ready")
		player:SetAttribute("Ready", ready)
		Remotes.Notify:FireClient(player, if ready then "Ready. Waiting for the others." else "Not ready.", "money")
	elseif state == "playing" then
		if player:GetAttribute("DiedThisRun") then
			Remotes.Notify:FireClient(player, "You died this run. Wait for the next descent.", "warn")
		elseif aliveRoot(player) then
			(player.Character :: Model):PivotTo(levelSpawnCFrame(math.random(1, 16)))
		end
	end
end)

-- Hub countdown, ready check, and the signs.
task.spawn(function()
	while true do
		task.wait(0.25)
		local state = workspace:GetAttribute("RunState")
		local players = Players:GetPlayers()
		local ready = 0
		for _, p in players do
			if p:GetAttribute("Ready") then
				ready += 1
			end
		end
		for c, label in hub.crewSigns do
			label.Text = `{Config.CREW_NAMES[c]}\n{#CrewService.members(c)}/{Config.CREW_SIZE}`
		end
		if state == "hub" then
			local endsAt = (workspace:GetAttribute("HubEndsAt") or now()) :: number
			if #players > 0 and ready == #players and endsAt - now() > Config.HUB_ALL_READY_SECONDS then
				endsAt = now() + Config.HUB_ALL_READY_SECONDS
				workspace:SetAttribute("HubEndsAt", endsAt)
			end
			workspace:SetAttribute("ReadyCount", ready)
			hub.liftSign.Text = `DESCENT IN {math.max(0, math.ceil(endsAt - now()))}s  ·  READY {ready}/{#players}`
			if now() >= endsAt and #players > 0 then
				descend(nil)
			end
		elseif state == "playing" then
			hub.liftSign.Text = "RUN UNDER WAY  ·  JOIN AT THE PANEL"
		else
			hub.liftSign.Text = "STAND BY"
		end
	end
end)

-- The dead sit out the rest of the run.
local function watchDeaths(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			if workspace:GetAttribute("RunState") == "playing" then
				player:SetAttribute("DiedThisRun", true)
				player:SetAttribute("Stat_Deaths", ((player:GetAttribute("Stat_Deaths") or 0) :: number) + 1)
			end
		end)
	end)
end
Players.PlayerAdded:Connect(watchDeaths)
for _, p in Players:GetPlayers() do
	watchDeaths(p)
end

-- START ---------------------------------------------------------------------

CrewService.init()
ShopService.init()
DataService.init()
MonetisationService.init()
ArtefactService.init()
ShiftService.init()
Tenant.init()
Lampjaw.init()
MapService.init()
RunManager.init(startHub) -- after each run's results, everyone goes back to the hub

startHub()

-- The safehouse is built and lit: now let people spawn (in the safehouse).
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
	if not seedFromStudio and typeof(seed) == "number" and workspace:GetAttribute("RunState") == "hub" then
		descend(seed)
	end
end)
