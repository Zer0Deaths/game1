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
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local ArtefactService = {}

local worldFolder: Folder? = nil -- where artefacts lying in the level live

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
	player:SetAttribute("CarryCount", #items)
	player:SetAttribute("CarryWeight", weight)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = math.max(Config.MIN_WALK_SPEED, Config.WALK_SPEED - weight * Config.SPEED_PER_WEIGHT)
	end
end

-- Put a tool on the floor at a position, ready to be picked up.
local function placeInWorld(tool: Tool, position: Vector3, yaw: number)
	local handle = handleOf(tool)
	tool.Parent = worldFolder
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
	if not humanoid or humanoid.Health <= 0 or tool.Parent ~= worldFolder then
		return
	end
	if #ArtefactService.carried(player) >= Config.MAX_CARRY then
		Remotes.Notify:FireClient(player, `Hands full ({Config.MAX_CARRY} max). Drop something with G.`, "warn")
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

-- Scatter artefacts across the level. cellCenter converts a grid cell
-- to a world position (from LevelBuilder).
function ArtefactService.spawnAll(layout: LevelGen.Layout, levelModel: Instance, cellCenter: (number, number) -> Vector3)
	local folder = Instance.new("Folder")
	folder.Name = "Artefacts"
	folder.Parent = levelModel
	worldFolder = folder

	local rng = LevelGen.makeRng(layout.seed + 101)
	for _ = 1, Config.ARTEFACT_COUNT do
		local x, z
		repeat
			x, z = rng.int(1, layout.width), rng.int(1, layout.depth)
		until not (x == layout.spawn.x and z == layout.spawn.z) and not (x == layout.exit.x and z == layout.exit.z)
		local def = pickDef(rng)
		local value = rng.int(def.minValue, def.maxValue)
		local center = cellCenter(x, z)
		local offset = Vector3.new((rng.float() - 0.5) * 12, 0, (rng.float() - 0.5) * 12)
		placeInWorld(makeArtefact(def, value), center + offset, rng.float() * math.pi * 2)
	end
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

-- Unsold loot is lost when a run ends.
function ArtefactService.clearCarried()
	for _, player in Players:GetPlayers() do
		ArtefactService.takeAll(player)
	end
end

local function dropHeld(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root or not worldFolder then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or not tool:GetAttribute("Artefact") then
		Remotes.Notify:FireClient(player, "Hold an artefact (number keys) to drop it.", "warn")
		return
	end
	local pos = root.Position + root.CFrame.LookVector * 3
	local _, yaw, _ = root.CFrame:ToOrientation()
	placeInWorld(tool, pos, yaw)
	ArtefactService.refreshCarry(player)
end

local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	ArtefactService.refreshCarry(player)
	-- Track changes in hand/hotbar so speed always matches the load.
	character.ChildAdded:Connect(function()
		ArtefactService.refreshCarry(player)
	end)
	humanoid.Died:Connect(function()
		-- Your loot spills on the floor where you die. Someone can come back for it.
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root or not worldFolder then
			return
		end
		for _, tool in ArtefactService.carried(player) do
			local scatter = Vector3.new(math.random() * 4 - 2, 0, math.random() * 4 - 2)
			placeInWorld(tool, root.Position + scatter, math.random() * math.pi * 2)
		end
		player:SetAttribute("CarryCount", 0)
		player:SetAttribute("CarryWeight", 0)
	end)
end

function ArtefactService.init()
	Remotes.DropArtefact.OnServerEvent:Connect(dropHeld)
	local function onPlayer(player: Player)
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
