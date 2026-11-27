--!strict
-- MapService: each crew's shared map. Wherever any crew member looks,
-- those cells are drawn on the whole crew's map (M key). After a Shift the
-- old drawing stays but is marked stale until someone looks again, because
-- the maze may have rebuilt there. The server decides what's known;
-- clients only draw it. One map per crew level (Sublevels creates it).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MapKnowledge = require(Shared:WaitForChild("MapKnowledge"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local MapService = {}

export type CrewMap = { destroy: () -> () }

local active: { [number]: { send: (Player?) -> () } } = {}

local function crewMembers(crew: number): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Crew") == crew then
			table.insert(list, p)
		end
	end
	return list
end

function MapService.create(ctx: any): CrewMap
	local knowledge: MapKnowledge.Knowledge = {}
	local alive = true
	local state: Folder = ctx.state

	local function send(player: Player?)
		local l = ctx.layout
		local entries = {}
		for _, e in knowledge do
			table.insert(entries, e)
		end
		for _, p in if player then { player } else crewMembers(ctx.crew) do
			Remotes.MapSync:FireClient(p, "reset", l.width, l.depth)
			Remotes.MapSync:FireClient(p, "cells", entries)
		end
	end
	active[ctx.crew] = { send = send }
	send(nil)

	task.spawn(function()
		while alive do
			task.wait(Config.MAP_UPDATE_SECONDS)
			local l = ctx.layout
			if not alive or state:GetAttribute("Shifting") or state:GetAttribute("State") ~= "playing" then
				continue
			end
			local shift = (state:GetAttribute("ShiftCount") or 0) :: number
			local changed: { MapKnowledge.Entry } = {}
			for _, player in crewMembers(ctx.crew) do
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if humanoid and root and humanoid.Health > 0 and LevelBuilder.inLevel(l, root.Position, ctx.origin) then
					local cx, cz = LevelBuilder.cellOf(l, root.Position, ctx.origin)
					for _, e in MapKnowledge.reveal(knowledge, l, cx, cz, shift, Config.MAP_SIGHT_CELLS) do
						table.insert(changed, e)
					end
				end
			end
			if #changed > 0 then
				for _, p in crewMembers(ctx.crew) do
					Remotes.MapSync:FireClient(p, "cells", changed)
				end
			end
		end
	end)

	return {
		destroy = function()
			alive = false
			if active[ctx.crew] and active[ctx.crew].send == send then
				active[ctx.crew] = nil
			end
		end,
	}
end

function MapService.init()
	Remotes.guard(Remotes.MapRequest, 0.5, function(player)
		local m = active[(player:GetAttribute("Crew") or 0) :: number]
		if m then
			m.send(player)
		end
	end)
end

return MapService
