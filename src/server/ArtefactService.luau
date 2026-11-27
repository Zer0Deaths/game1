--!strict
-- ArtefactService: spawns artefacts in the level and handles picking
-- them up, dropping them, carry weight and dropping loot on death.
--
-- Each artefact is a Roblox Tool, so it shows in the hotbar and can be
-- held in hand. Pick up with the on-screen prompt (E on PC), drop with G.
-- Touch pickup is switched off so the carry limit can't be bypassed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Artefacts = require(Shared:WaitForChild("Artefacts"))
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local Surfaces = require(Shared:WaitForChild("Surfaces"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local NoiseService = require(script.Parent:WaitForChild("NoiseService"))

local ArtefactService = {}

-- Each crew's level has its own "Artefacts" folder. Sublevels tells us
-- which one a player is standing in (for drops and death spills).
local folderFor: (Player) -> Folder? = function()
	return nil
end
function ArtefactService.setFolderResolver(fn: (Player) -> Folder?)
	folderFor = fn
end

local function handleOf(tool: Tool): BasePart
	return tool:FindFirstChild("Handle") :: BasePart
end

local function promptOf(tool: Tool): ProximityPrompt?
	return handleOf(tool):FindFirstChildOfClass("ProximityPrompt")
end

-- All artefacts a player holds: hotbar (Backpack) plus the one in hand.
function ArtefactService.carried(player: Player): { Tool }
	local list = {}
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("Artefact") then
					table.insert(list, child)
				end
			end
		end
	end
	return list
end

function ArtefactService.refreshCarry(player: Player)
	local weight = 0
	local items = ArtefactService.carried(player)
	for _, tool in items do
		weight += tool:GetAttribute("Weight") or 0
	end
	-- Speed, jump and stamina are applied on the player's own device by
	-- Movement.client, which reads these attributes.
	player:SetAttribute("CarryCount", #items)
	player:SetAttribute("CarryWeight", weight)
	ArtefactService.updateBackLoad(player)
end

-- Show loot that isn't in your hand strapped to your back, so everyone
-- can see who is hauling what. Purely visual copies, welded to the torso.
function ArtefactService.updateBackLoad(player: Player)
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not character or not torso then
		return
	end
	local old = character:FindFirstChild("BackLoad")
	if old then
		old:Destroy()
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "BackLoad"
	local stackHeight = 0
	for _, tool in backpack:GetChildren() do
		if not tool:IsA("Tool") or not tool:GetAttribute("Artefact") then
			continue
		end
		local copy = handleOf(tool):Clone()
		copy.Name = tool.Name
		for _, child in copy:GetChildren() do
			child:Destroy() -- drop the pickup prompt
		end
		copy.Anchored = false
		copy.CanCollide = false
		copy.CanQuery = false
		copy.Massless = true
		-- Stack items up the back, biggest side flat against the spine.
		local depth = torso.Size.Z / 2 + math.min(copy.Size.X, copy.Size.Z) / 2 + 0.1
		local lift = -torso.Size.Y / 2 + stackHeight + copy.Size.Y / 2
		copy.CFrame = torso.CFrame * CFrame.new(0, lift, depth)
		stackHeight += copy.Size.Y * 0.85
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = copy
		weld.Parent = copy
		copy.Parent = folder
	end
	folder.Parent = character
end

-- Put a tool on the floor at a position, ready to be picked up.
local function placeInWorld(tool: Tool, position: Vector3, yaw: number, folder: Instance)
	local handle = handleOf(tool)
	tool.Parent = folder
	handle.Anchored = true
	handle.CanCollide = true
	handle.Massless = false
	handle.CFrame = CFrame.new(position.X, handle.Size.Y / 2 + 0.05, position.Z) * CFrame.Angles(0, yaw, 0)
	local prompt = promptOf(tool)
	if prompt then
		prompt.Enabled = true
	end
end

local function pickUp(player: Player, tool: Tool)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local parent = tool.Parent
	if not humanoid or humanoid.Health <= 0 or not parent or parent.Name ~= "Artefacts" or not parent:IsDescendantOf(workspace) then
		return
	end
	local maxCarry = Config.MAX_CARRY + ((player:GetAttribute("CarryBonus") or 0) :: number)
	if #ArtefactService.carried(player) >= maxCarry then
		Remotes.Notify:FireClient(player, `Hands full ({maxCarry} max). Drop something with G.`, "warn")
		return
	end
	local handle = handleOf(tool)
	local prompt = promptOf(tool)
	if prompt then
		prompt.Enabled = false
	end
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	tool.Parent = player:FindFirstChildOfClass("Backpack")
	ArtefactService.refreshCarry(player)
	Remotes.Fx:FireAllClients("pickup", handle.Position)
	Remotes.Notify:FireClient(player, `Picked up {tool.Name} (${tool:GetAttribute("Value")})`, "info")
end

local function makeArtefact(def: Artefacts.ArtefactDef, value: number): Tool
	local tool = Instance.new("Tool")
	tool.Name = def.name
	tool.ToolTip = `{def.name}  ${value}`
	tool.CanBeDropped = false -- we handle dropping ourselves (G key)
	tool.RequiresHandle = true
	tool:SetAttribute("Artefact", def.id)
	tool:SetAttribute("Value", value)
	tool:SetAttribute("Weight", def.weight)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = def.shape
	handle.Size = def.size
	handle.Color = def.color
	handle.Material = def.material
	handle.CanTouch = false -- no touch pickup
	Surfaces.auto(handle) -- PBR metal, rust, plastic...
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = tool

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = `{def.name}  ${value}`
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.2
	prompt.Parent = handle
	prompt.Triggered:Connect(function(player)
		pickUp(player, tool)
	end)

	return tool
end

local function pickDef(rng): Artefacts.ArtefactDef
	local total = 0
	for _, def in Artefacts do
		total += def.rarity
	end
	local roll = rng.float() * total
	for _, def in Artefacts do
		roll -= def.rarity
		if roll <= 0 then
			return def
		end
	end
	return Artefacts[1]
end

-- Scatter artefacts across a level. cellCenter converts a grid cell to a
-- world position. Deeper sublevels pass a valueMultiplier > 1.
function ArtefactService.spawnAll(layout: LevelGen.Layout, levelModel: Instance, cellCenter: (number, number) -> Vector3, count: number, valueMultiplier: number): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Artefacts"
	folder.Parent = levelModel

	local rng = LevelGen.makeRng(layout.seed + 101)
	for _ = 1, count do
		local x, z
		repeat
			x, z = rng.int(1, layout.width), rng.int(1, layout.depth)
		until not (x == layout.spawn.x and z == layout.spawn.z) and not (x == layout.exit.x and z == layout.exit.z)
		local def = pickDef(rng)
		local value = math.floor(rng.int(def.minValue, def.maxValue) * valueMultiplier + 0.5)
		local center = cellCenter(x, z)
		local offset = Vector3.new((rng.float() - 0.5) * 12, 0, (rng.float() - 0.5) * 12)
		placeInWorld(makeArtefact(def, value), center + offset, rng.float() * math.pi * 2, folder)
	end
	return folder
end

-- Remove every artefact a player is carrying and return their total value.
function ArtefactService.takeAll(player: Player): (number, number)
	local total, count = 0, 0
	for _, tool in ArtefactService.carried(player) do
		total += tool:GetAttribute("Value") or 0
		count += 1
		tool:Destroy()
	end
	ArtefactService.refreshCarry(player)
	return total, count
end

local function dropHeld(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local folder = folderFor(player)
	if not character or not root or not folder then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or not tool:GetAttribute("Artefact") then
		Remotes.Notify:FireClient(player, "Hold an artefact (number keys) to drop it.", "warn")
		return
	end
	local pos = root.Position + root.CFrame.LookVector * 3
	local _, yaw, _ = root.CFrame:ToOrientation()
	placeInWorld(tool, pos, yaw, folder)
	ArtefactService.refreshCarry(player)
	Remotes.Fx:FireAllClients("drop", pos)
	-- Loot hitting the floor is loud.
	NoiseService.emit(pos, Config.TENANT.hearDrop, player)
end

local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	ArtefactService.refreshCarry(player)
	-- Track changes in hand/hotbar so speed always matches the load.
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			ArtefactService.refreshCarry(player)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			ArtefactService.refreshCarry(player)
		end
	end)
	humanoid.Died:Connect(function()
		-- Your loot spills on the floor where you die. Someone can come back for it.
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			Remotes.Fx:FireAllClients("death", root.Position)
		end
		local folder = folderFor(player)
		if not root or not folder then
			return
		end
		for _, tool in ArtefactService.carried(player) do
			local scatter = Vector3.new(math.random() * 4 - 2, 0, math.random() * 4 - 2)
			placeInWorld(tool, root.Position + scatter, math.random() * math.pi * 2, folder)
		end
		player:SetAttribute("CarryCount", 0)
		player:SetAttribute("CarryWeight", 0)
		local backLoad = character:FindFirstChild("BackLoad")
		if backLoad then
			backLoad:Destroy()
		end
	end)
end

function ArtefactService.init()
	local StarterPlayer = game:GetService("StarterPlayer")
	StarterPlayer.EnableMouseLockOption = false
	-- First person only, for everyone.
	StarterPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	Remotes.guard(Remotes.DropArtefact, 4, dropHeld)
	local function onPlayer(player: Player)
		-- Left Shift is our sprint key, so Roblox's Shift Lock has to go.
		player.DevEnableMouseLock = false
		-- First person only. Roblox hides your own body and the loot on your
		-- back from your own camera; held items still show in your hand.
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			onCharacter(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return ArtefactService
