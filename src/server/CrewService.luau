--!strict
-- CrewService: splits the server into crews (Config.CREW_COUNT crews of up
-- to Config.CREW_SIZE). Each player gets a "Crew" attribute (1-4) and a
-- "Cash" attribute (their own money for the safehouse shop).
-- Each crew's live state (sublevel, quota, bank...) is on its CrewState
-- folder, written by Sublevels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Crews = require(Shared:WaitForChild("Crews"))

local CrewService = {}

function CrewService.members(crew: number): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Crew") == crew then
			table.insert(list, p)
		end
	end
	return list
end

local function counts(except: Player?): { number }
	local c = table.create(Config.CREW_COUNT, 0)
	for _, p in Players:GetPlayers() do
		local crew = p:GetAttribute("Crew")
		if p ~= except and typeof(crew) == "number" then
			c[crew] += 1
		end
	end
	return c
end

-- Move a player to another crew if it has room. Returns true on success.
function CrewService.switch(player: Player, crew: number): boolean
	if crew < 1 or crew > Config.CREW_COUNT or player:GetAttribute("Crew") == crew then
		return false
	end
	if counts(player)[crew] >= Config.CREW_SIZE then
		return false
	end
	player:SetAttribute("Crew", crew)
	return true
end

local function assign(player: Player)
	local crew = Crews.pick(counts(player), Config.CREW_COUNT, Config.CREW_SIZE) or 1
	player:SetAttribute("Crew", crew)
	if player:GetAttribute("Cash") == nil then
		player:SetAttribute("Cash", 0)
	end
end

function CrewService.init()
	Players.PlayerAdded:Connect(assign)
	for _, p in Players:GetPlayers() do
		assign(p)
	end
end

return CrewService
