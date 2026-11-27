-- Runs on the server. Synced to ServerScriptService.Server.main
-- Sets up the world and the safehouse. The crew loop itself (sublevels,
-- quota, the lift, wipes) is in Sublevels.luau:
--   SAFEHOUSE  pick a crew, shop, press Ready. A crew drops into its own
--              sublevel 1 when everyone in it is ready.
--   SUBLEVEL   meet the crew quota, get everyone alive into the lift, then
--              go deeper or return to the safehouse. Out of time or all
--              dead: the crew is wiped and comes back here.
--
-- Studio testing: Workspace attributes "LevelSeed" (number) drops your
-- crew straight into that layout; "ForceShift" (bool) triggers a Shift.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- WaitForChild instead of a dot: if Rojo is mid-sync, this waits instead of crashing.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CrewState = require(Shared:WaitForChild("CrewState"))

local Atmosphere = require(script.Parent:WaitForChild("Atmosphere"))
local ArtefactService = require(script.Parent:WaitForChild("ArtefactService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local Uniform = require(script.Parent:WaitForChild("Uniform"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local Sublevels = require(script.Parent:WaitForChild("Sublevels"))
local CrewService = require(script.Parent:WaitForChild("CrewService"))
local Safehouse = require(script.Parent:WaitForChild("Safehouse"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MonetisationService = require(script.Parent:WaitForChild("MonetisationService"))
local Materials = require(script.Parent:WaitForChild("Materials"))

-- Dark, hazy, sickly-yellow lighting. See Atmosphere.luau to tweak the look.
Atmosphere.apply()
Materials.init() -- SHIFT's textures, once uploaded

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

local function aliveRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end
	return nil
end

-- HUB -----------------------------------------------------------------------

local hub = Safehouse.build()

local function sendToHub(player: Player, index: number)
	local root = aliveRoot(player)
	if root then
		(player.Character :: Model):PivotTo(hub.arrivalCFrame(index))
	end
end

local function inSafehouse(player: Player): boolean
	local root = aliveRoot(player)
	return root ~= nil and root.Position.X < 0
end

-- Crew board.
for c, pr in hub.crewPrompts do
	pr.Triggered:Connect(function(player)
		if player:GetAttribute("Crew") ~= c and not inSafehouse(player) then
			return
		end
		if CrewService.switch(player, c) then
			player:SetAttribute("Ready", false)
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

-- Descent lift: Ready up with your crew, or join your crew's sublevel if
-- it's already down there (not if you died on this one: wait for the next).
hub.readyPrompt.Triggered:Connect(function(player)
	local crew = (player:GetAttribute("Crew") or 1) :: number
	local state = CrewState.folder(crew):GetAttribute("State")
	if state == "hub" or state == "countdown" then
		Sublevels.toggleReady(player)
	elseif state == "playing" then
		if player:GetAttribute("DiedThisRun") then
			Remotes.Notify:FireClient(player, "You died on this sublevel. You'll go down with your crew to the next one.", "warn")
		else
			Sublevels.join(player)
		end
	end
end)

-- The signs: each crew's state on the board, and a note at the lift.
task.spawn(function()
	while true do
		task.wait(0.5)
		for c, label in hub.crewSigns do
			local st = CrewState.folder(c)
			local state = st:GetAttribute("State")
			local where = if state == "playing" or state == "descending" or state == "cleared"
				then `SUBLEVEL {st:GetAttribute("Depth") or 1}`
				elseif state == "countdown" then "DROPPING"
				else `READY {st:GetAttribute("ReadyCount") or 0}/{#CrewService.members(c)}`
			label.Text = `{Config.CREW_NAMES[c]}\n{#CrewService.members(c)}/{Config.CREW_SIZE}  ·  {where}`
		end
		hub.liftSign.Text = "DESCENT  ·  YOUR CREW DROPS WHEN ALL ARE READY"
	end
end)

-- The dead sit out the rest of the run.
local function watchDeaths(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			if CrewState.folder((player:GetAttribute("Crew") or 1) :: number):GetAttribute("State") == "playing" and not inSafehouse(player) then
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
MapService.init()
Sublevels.init(sendToHub) -- each crew's sublevels; back to the safehouse after a wipe or by choice

-- The safehouse is built and lit: now let people spawn (in the safehouse).
Players.CharacterAutoLoads = true
for _, player in Players:GetPlayers() do
	if not player.Character then
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
end

-- Studio testing:
--   LevelSeed (number): drop the first player's crew straight into that layout.
--   ForceShift (bool): trigger a Shift in every crew's level now.
workspace:GetAttributeChangedSignal("LevelSeed"):Connect(function()
	local seed = workspace:GetAttribute("LevelSeed")
	local first = Players:GetPlayers()[1]
	if typeof(seed) == "number" and first then
		Sublevels.descendWithSeed((first:GetAttribute("Crew") or 1) :: number, seed)
	end
end)
workspace:GetAttributeChangedSignal("ForceShift"):Connect(function()
	if workspace:GetAttribute("ForceShift") == true then
		workspace:SetAttribute("ForceShift", false)
		Sublevels.forceShift()
	end
end)
