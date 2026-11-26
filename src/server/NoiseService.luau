--!strict
-- NoiseService: everything that makes a sound an entity can hear.
-- Players make noise just by moving (worked out here on the server from
-- their real speed, so nobody can cheat it), and other systems can report
-- one-off noises like dropped loot. Entities ask "what can I hear from
-- here?" and get the loudest thing in range.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local NoiseService = {}

export type Noise = {
	position: Vector3,
	radius: number, -- how far away it can be heard, in studs
	player: Player?, -- who made it, if anyone
	at: number, -- os.clock() when it happened
}

local events: { Noise } = {}
local EVENT_LIFETIME = 1.5

-- A one-off noise (dropped loot, a door, ...). radius = how far it carries.
function NoiseService.emit(position: Vector3, radius: number, player: Player?)
	table.insert(events, { position = position, radius = radius, player = player, at = os.clock() })
end

-- How far this player's movement carries right now (0 = silent).
function NoiseService.playerRadius(player: Player): number
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then
		return 0
	end
	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	if speed < 2 then
		return 0
	end
	local T = Config.TENANT
	local base = if speed > Config.WALK_SPEED * 1.15 then T.hearSprint else T.hearWalk
	local weight = (player:GetAttribute("CarryWeight") or 0) :: number
	local radius = base + weight * T.hearPerWeight
	if player:GetAttribute("Run_softboots") then
		radius *= Config.SOFTBOOTS_NOISE -- shop: soft-sole boots
	end
	return radius
end

-- Everything audible from `from`: moving players and recent one-off noises.
function NoiseService.audible(from: Vector3): { Noise }
	local now = os.clock()
	local heard: { Noise } = {}
	for _, player in Players:GetPlayers() do
		local radius = NoiseService.playerRadius(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if radius > 0 and root and (root.Position - from).Magnitude <= radius then
			table.insert(heard, { position = root.Position, radius = radius, player = player, at = now })
		end
	end
	for i = #events, 1, -1 do
		local e = events[i]
		if now - e.at > EVENT_LIFETIME then
			table.remove(events, i)
		elseif (e.position - from).Magnitude <= e.radius then
			table.insert(heard, e)
		end
	end
	return heard
end

return NoiseService
