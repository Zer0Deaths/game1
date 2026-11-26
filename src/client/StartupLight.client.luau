--!strict
-- Fixes the black start. For about 15 s after joining, Roblox hasn't yet
-- worked out how the ceiling lights fall on the walls, so the level looked
-- pitch black. This lights the level with a warm ambient on THIS device
-- only, then fades it down to the normal mood once the lamps have caught up.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local started = os.clock()
local connection: RBXScriptConnection
connection = RunService.RenderStepped:Connect(function()
	local t = os.clock() - started
	local alpha = math.clamp((t - Config.START_AMBIENT_HOLD) / Config.START_AMBIENT_FADE, 0, 1)
	local colour = Config.START_AMBIENT:Lerp(Config.AMBIENT, alpha)
	-- Never brighten a Shift blackout: that must stay dark.
	if workspace:GetAttribute("Shifting") then
		colour = Config.AMBIENT
	end
	Lighting.Ambient = colour
	Lighting.OutdoorAmbient = colour
	if alpha >= 1 then
		connection:Disconnect()
	end
end)
