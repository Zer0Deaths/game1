--!strict
-- Fixes the black start. For about 15 s after a level appears, Roblox
-- hasn't yet worked out how the ceiling lights fall on the walls, so the
-- level looked pitch black. This lights things with a warm ambient on THIS
-- device only, then fades it down to the normal mood once the lamps have
-- caught up. It runs when you join and again every time your crew lands
-- on a new sublevel (a brand new level each time).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local connection: RBXScriptConnection? = nil

local function fadeIn()
	if connection then
		connection:Disconnect()
	end
	local started = os.clock()
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
		if alpha >= 1 and connection then
			connection:Disconnect()
			connection = nil
		end
	end)
end

fadeIn()
-- A new sublevel: Depth changes (mirrored from the crew's state).
workspace:GetAttributeChangedSignal("Depth"):Connect(function()
	if ((workspace:GetAttribute("Depth") or 0) :: number) > 0 then
		fadeIn()
	end
end)
