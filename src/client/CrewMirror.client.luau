--!strict
-- CrewMirror: copies your own crew's live state (ReplicatedStorage.CrewState)
-- onto Workspace attributes on this device only, so the lights, HUD,
-- compass, map and sounds can just read Workspace. Each crew has its own
-- level, so each device mirrors its own crew. Also gives this device the
-- haze and colour grade of the level type it's in.
--
--   CrewState     ->  Workspace (this device)
--   State         ->  RunState ("playing", "hub", or "intermission" for the
--                     moments between sublevels) and CrewRunState (raw)
--   EndsAt        ->  RunEndsAt
--   Quota/Banked  ->  CrewQuota / CrewBanked
--   everything else keeps its name

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrewState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CrewState"))

local player = Players.LocalPlayer

local RENAME = {
	EndsAt = "RunEndsAt",
	Quota = "CrewQuota",
	Banked = "CrewBanked",
}

local function runState(raw: any): string
	if raw == "playing" then
		return "playing"
	elseif raw == "hub" or raw == "countdown" or raw == nil then
		return "hub"
	end
	return "intermission"
end

local function copy(folder: Folder, name: string)
	local value = folder:GetAttribute(name)
	if name == "State" then
		workspace:SetAttribute("RunState", runState(value))
		workspace:SetAttribute("CrewRunState", value)
	else
		workspace:SetAttribute(RENAME[name] or name, value)
	end
end

local current: Folder? = nil
local connection: RBXScriptConnection? = nil

local function follow()
	local crew = player:GetAttribute("Crew")
	if typeof(crew) ~= "number" then
		return
	end
	local folder = CrewState.folder(crew)
	if folder == current then
		return
	end
	if connection then
		connection:Disconnect()
	end
	current = folder
	for name in folder:GetAttributes() do
		copy(folder, name)
	end
	connection = folder.AttributeChanged:Connect(function(name)
		copy(folder, name)
	end)
end

player:GetAttributeChangedSignal("Crew"):Connect(follow)
follow()

-- Haze and colour grade: the level type's while you're in your crew's
-- level, the safehouse's (the server's defaults) everywhere else.
local atmo = Lighting:WaitForChild("LiminalHaze", 10) :: Atmosphere?
local grade = Lighting:WaitForChild("LiminalGrade", 10) :: ColorCorrectionEffect?
local defaults = {
	colour = atmo and atmo.Color,
	decay = atmo and atmo.Decay,
	density = atmo and atmo.Density,
	tint = grade and grade.TintColor,
}
task.spawn(function()
	while true do
		task.wait(0.5)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local inLevel = root ~= nil and root.Position.X >= 0 and workspace:GetAttribute("RunState") == "playing"
		local colour = if inLevel then workspace:GetAttribute("HazeColour") else defaults.colour
		local decay = if inLevel then workspace:GetAttribute("HazeDecay") else defaults.decay
		local density = if inLevel then workspace:GetAttribute("HazeDensity") else defaults.density
		local tint = if inLevel then workspace:GetAttribute("Tint") else defaults.tint
		if atmo then
			if typeof(colour) == "Color3" then
				atmo.Color = colour
			end
			if typeof(decay) == "Color3" then
				atmo.Decay = decay
			end
			if typeof(density) == "number" then
				atmo.Density = density
			end
		end
		if grade and typeof(tint) == "Color3" then
			grade.TintColor = tint
		end
	end
end)
