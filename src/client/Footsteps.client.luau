-- Footsteps that match the floor: muffled thuds on carpet, clicks on hard
-- floors, clanks on the metal lift plate. Heavier and slower when a
-- player is loaded, quicker when sprinting.
--
-- Runs for EVERY character on this device (yours and other players'),
-- so you hear your crew walking nearby. The floor is found with a
-- raycast, which works for other players too.
--
-- Until the footstep sounds are uploaded (see Shared.SoundIds), Roblox's
-- default footstep stays on as a fallback.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundIds"))

local STRIDE = 4.2 -- studs between steps at a walk
local SPRINT_STRIDE = 5.6

local SURFACE: { [Enum.Material]: string } = {
	[Enum.Material.Carpet] = "STEP_CARPET",
	[Enum.Material.Fabric] = "STEP_CARPET",
	[Enum.Material.DiamondPlate] = "STEP_METAL",
	[Enum.Material.Metal] = "STEP_METAL",
	[Enum.Material.CorrodedMetal] = "STEP_METAL",
	[Enum.Material.Foil] = "STEP_METAL",
}

type Walker = { distance: number, sounds: { [string]: Sound } }
local walkers: { [Model]: Walker } = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function soundFor(walker: Walker, root: BasePart, key: string): Sound?
	local id = SoundIds.get(key)
	if not id then
		return nil
	end
	local sound = walker.sounds[key]
	if not sound or sound.Parent ~= root then
		sound = Instance.new("Sound")
		sound.Name = key
		sound.RollOffMinDistance = 6
		sound.RollOffMaxDistance = 70 -- hear crewmates a corridor or two away
		sound.Parent = root
		walker.sounds[key] = sound
	end
	if sound.SoundId ~= id then
		sound.SoundId = id
	end
	return sound
end

local function floorMaterial(character: Model, root: BasePart): Enum.Material?
	rayParams.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -4.5, 0), rayParams)
	return hit and hit.Material
end

RunService.Heartbeat:Connect(function(dt)
	local haveCustom = SoundIds.get("STEP_CARPET") ~= nil
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not root or not humanoid or humanoid.Health <= 0 then
			continue
		end

		-- Mute Roblox's generic footstep once ours are available.
		local default = root:FindFirstChild("Running")
		if haveCustom and default and default:IsA("Sound") then
			default.Volume = 0
		end

		local walker = walkers[character]
		if not walker then
			walker = { distance = 0, sounds = {} }
			walkers[character] = walker
		end

		local material = floorMaterial(character, root)
		local v = root.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		if not material or speed < 1 then
			walker.distance = STRIDE * 0.6 -- first step lands soon after you start moving
			continue
		end

		local weight = player:GetAttribute("CarryWeight") or 0
		local heavy = math.clamp(weight / 14, 0, 1)
		local sprinting = speed > 19
		local stride = if sprinting then SPRINT_STRIDE else STRIDE
		walker.distance += speed * dt
		if walker.distance >= stride then
			walker.distance = 0
			local sound = soundFor(walker, root, SURFACE[material] or "STEP_HARD")
			if sound then
				sound.PlaybackSpeed = (0.92 + math.random() * 0.16) * (1 - heavy * 0.22)
				sound.Volume = (if sprinting then 0.75 else 0.55) + heavy * 0.35
				sound:Play()
			end
		end
	end
	for character in walkers do
		if not character.Parent then
			walkers[character] = nil
		end
	end
end)
