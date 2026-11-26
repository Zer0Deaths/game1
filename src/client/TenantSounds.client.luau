--!strict
-- The Tenant is heard before it's seen: a low, slow drone that carries a
-- long way and heavy footfalls that get faster when it hunts. Played on
-- this device only, from the uploaded sounds (see SoundIds). No camera
-- effects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundIds"))

local function makeSound(parent: Instance, key: string, speed: number, volume: number, maxDistance: number, looped: boolean): Sound
	local s = Instance.new("Sound")
	s.Name = key
	s.PlaybackSpeed = speed
	s.Volume = volume
	s.Looped = looped
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 10
	s.RollOffMaxDistance = maxDistance
	s.Parent = parent
	return s
end

local function attach(model: Model)
	local root = model:WaitForChild("Root", 5) :: BasePart?
	if not root then
		return
	end
	local drone = makeSound(root, "Drone", 0.22, 1.4, 120, true)
	local step = makeSound(root, "Step", 0.45, 1.6, 110, false)
	-- The sound IDs are worked out at runtime; wait until they are known.
	task.spawn(function()
		while model.Parent and not (SoundIds.get("HUM") and SoundIds.get("STEP_HARD")) do
			task.wait(1)
		end
		drone.SoundId = SoundIds.get("HUM") or ""
		step.SoundId = SoundIds.get("STEP_HARD") or ""
		drone:Play()
	end)

	local last = root.Position
	local travelled = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		if not root.Parent or root:IsDescendantOf(workspace) == false then
			drone.Volume = 0
			last = root.Position
			if not model.Parent then
				connection:Disconnect()
			end
			return
		end
		local hunting = model:GetAttribute("State") == "chase"
		drone.Volume = if hunting then 2 else 1.4
		drone.PlaybackSpeed = if hunting then 0.3 else 0.22
		local moved = (root.Position - last).Magnitude
		last = root.Position
		if moved > 5 then
			travelled = 0 -- it appeared somewhere new; no step for a teleport
			return
		end
		travelled += moved
		if travelled >= 4.5 and step.SoundId ~= "" then
			travelled = 0
			step.PlaybackSpeed = 0.4 + math.random() * 0.1
			step:Play()
		end
	end)
end

workspace.ChildAdded:Connect(function(child)
	if child.Name == "Tenant" and child:IsA("Model") then
		attach(child)
	end
end)
local existing = workspace:FindFirstChild("Tenant")
if existing and existing:IsA("Model") then
	attach(existing)
end
