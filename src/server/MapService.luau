--!strict
-- MapService: the crew's shared map. Wherever any player looks, those cells
-- are drawn on everyone's map (M key). After a Shift the old drawing stays
-- but is marked stale until someone looks again, because the maze may have
-- rebuilt there. The server decides what's known; clients only draw it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local MapKnowledge = require(Shared:WaitForChild("MapKnowledge"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local MapService = {}

local layout: LevelGen.Layout? = nil
local knowledge: MapKnowledge.Knowledge = {}

local function sendAll(player: Player?)
	local l = layout
	if not l then
		return
	end
	local entries = {}
	for _, e in knowledge do
		table.insert(entries, e)
	end
	if player then
		Remotes.MapSync:FireClient(player, "reset", l.width, l.depth)
		Remotes.MapSync:FireClient(player, "cells", entries)
	else
		Remotes.MapSync:FireAllClients("reset", l.width, l.depth)
		Remotes.MapSync:FireAllClients("cells", entries)
	end
end

function MapService.setLevel(newLayout: LevelGen.Layout)
	layout = newLayout
	knowledge = {}
	sendAll(nil)
end

local function update()
	local l = layout
	if not l or workspace:GetAttribute("Shifting") then
		return
	end
	local shift = (workspace:GetAttribute("ShiftCount") or 0) :: number
	local changed: { MapKnowledge.Entry } = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and root and humanoid.Health > 0 then
			local cx = math.clamp(math.floor(root.Position.X / LevelBuilder.CELL) + 1, 1, l.width)
			local cz = math.clamp(math.floor(root.Position.Z / LevelBuilder.CELL) + 1, 1, l.depth)
			for _, e in MapKnowledge.reveal(knowledge, l, cx, cz, shift, Config.MAP_SIGHT_CELLS) do
				table.insert(changed, e)
			end
		end
	end
	if #changed > 0 then
		Remotes.MapSync:FireAllClients("cells", changed)
	end
end

function MapService.init()
	Remotes.MapRequest.OnServerEvent:Connect(function(player)
		sendAll(player)
	end)
	task.spawn(function()
		while true do
			task.wait(Config.MAP_UPDATE_SECONDS)
			update()
		end
	end)
end

return MapService
