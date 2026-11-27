--!strict
-- CrewState: each crew's live state, as attributes on a Folder per crew
-- (ReplicatedStorage.CrewState.Crew1 .. Crew4). The server writes them
-- (Sublevels, ShiftService, Lampjaw, Quiet); every device reads its own crew's.
--
--   State        "hub" | "countdown" | "playing" | "descending" | "cleared" | "wiped"
--   Depth        sublevel number (0 in the safehouse)
--   Quota, Banked
--   EndsAt       server time the sublevel's timer runs out
--   DescendAt    server time the lift drops (countdown / descending)
--   LiftReady    quota met: everyone alive to the lift
--   Aboard, Needed  crew members in the lift / alive in the level
--   LiftPosition, LevelName, LightColour, HazeColour, HazeDecay, HazeDensity, Tint
--   ShiftWarning, Shifting, ShiftCount, LampjawCell
--   QuietState ("idle" | "falling" | "silent"), QuietCell, QuietRadius

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CrewState = {}

function CrewState.folder(crew: number): Folder
	if RunService:IsServer() then
		local root = ReplicatedStorage:FindFirstChild("CrewState")
		if not root then
			root = Instance.new("Folder")
			root.Name = "CrewState"
			root.Parent = ReplicatedStorage
		end
		local f = (root :: Instance):FindFirstChild(`Crew{crew}`)
		if not f then
			f = Instance.new("Folder")
			f.Name = `Crew{crew}`
			f.Parent = root
		end
		return f :: Folder
	end
	return ReplicatedStorage:WaitForChild("CrewState"):WaitForChild(`Crew{crew}`) :: Folder
end

return CrewState
