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
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local Meshes = require(script.Parent:WaitForChild("Meshes"))

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
			if child.Name ~= "Visual" then
				child:Destroy() -- drop the pickup prompt
			end
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
local function placeAt(tool: Tool, cf: CFrame, folder: Instance)
	local handle = handleOf(tool)
	tool.Parent = folder
	handle.Anchored = true
	handle.CanCollide = true
	handle.Massless = false
	handle.CFrame = cf
	local prompt = promptOf(tool)
	if prompt then
		prompt.Enabled = true
	end
	-- Its Blender model, welded to the Handle (which stays as the hitbox).
	-- Items are modelled with their bottom at 0, so the model's frame is
	-- the bottom of the Handle. Until the model loads it's the plain part.
	if not handle:FindFirstChild("Visual") and not tool:GetAttribute("Dressed") then
		local id = tool:GetAttribute("Artefact")
		if typeof(id) == "string" and Meshes.attach(`item_{id}`, handle, CFrame.new(0, -handle.Size.Y / 2, 0)) then
			tool:SetAttribute("Dressed", true)
		end
	end
end

local function placeInWorld(tool: Tool, position: Vector3, yaw: number, folder: Instance)
	placeAt(tool, CFrame.new(position.X, handleOf(tool).Size.Y / 2 + 0.05, position.Z) * CFrame.Angles(0, yaw, 0), folder)
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
	prompt.RequiresLineOfSight = true -- only loot you can actually see (walls block; props are CanQuery off so they don't)
	prompt.HoldDuration = Config.PICKUP_HOLD -- 0 = a single tap of E
	prompt.KeyboardKeyCode = Enum.KeyCode.E
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
-- Scatter artefacts across a level. cellCenter converts a grid cell to a
-- world position. Deeper sublevels pass a valueMultiplier > 1. `shelves`
-- are gaps on storage racks (LevelBuilder.shelfSlots): about
-- Config.SHELF_LOOT_SHARE of the loot is left on those instead of the floor.
function ArtefactService.spawnAll(
	layout: LevelGen.Layout,
	levelModel: Instance,
	cellCenter: (number, number) -> Vector3,
	count: number,
	valueMultiplier: number,
	shelves: { { cf: CFrame, width: number } }?
): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Artefacts"
	folder.Parent = levelModel

	local rng = LevelGen.makeRng(layout.seed + 101)
	local slots = table.clone(shelves or {})
	for i = #slots, 2, -1 do
		local j = rng.int(1, i)
		slots[i], slots[j] = slots[j], slots[i]
	end
	local onShelves = 0
	for _ = 1, count do
		local def = pickDef(rng)
		local value = math.floor(rng.int(def.minValue, def.maxValue) * valueMultiplier + 0.5)
		local tool = makeArtefact(def, value)
		local placed = false
		if #slots > 0 and rng.float() < Config.SHELF_LOOT_SHARE and def.size.Y < 1.9 then
			-- The first gap it fits in, lengthwise along the shelf.
			for i, slot in slots do
				if def.size.X <= slot.width - 0.2 then
					local cf = slot.cf * CFrame.new((rng.float() - 0.5) * (slot.width - def.size.X - 0.2), def.size.Y / 2 + 0.02, (rng.float() - 0.5) * 0.4)
					placeAt(tool, cf * CFrame.Angles(0, (rng.float() - 0.5) * 0.3, 0), folder)
					table.remove(slots, i)
					placed = true
					onShelves += 1
					break
				end
			end
		end
		if not placed then
			local x, z
			repeat
				x, z = rng.int(1, layout.width), rng.int(1, layout.depth)
			until not (x == layout.spawn.x and z == layout.spawn.z) and not (x == layout.exit.x and z == layout.exit.z)
			local center = cellCenter(x, z)
			local offset = Vector3.new((rng.float() - 0.5) * 12, 0, (rng.float() - 0.5) * 12)
			placeInWorld(tool, center + offset, rng.float() * math.pi * 2, folder)
		end
	end
	folder:SetAttribute("OnShelves", onShelves)
	return folder
end

-- After a level is built or a Shift rewires it, new props, pillars, door
-- frames and the lift can land on top of loot lying on the floor, which
-- then looks like it vanished. Move any covered item to the nearest clear
-- spot: first elsewhere in its own cell, then the nearest open cells
-- (walking distance, so it stays reachable). Nothing is ever deleted.
-- `blockers` are the folders/models that count as solid (Structure, lift).
-- Returns (items on the floor, items moved, items that found no clear spot
-- and were left where they were).
function ArtefactService.resettle(folder: Instance, layout: LevelGen.Layout, origin: Vector3, blockers: { Instance }): (number, number, number)
	-- Props are CanQuery = false (so the Tenant sees past them), which
	-- hides them from spatial queries too, so this checks the parts
	-- directly, bucketed by grid cell. Anything visible that rises above
	-- floor clutter height counts, and so do the invisible colliders left
	-- where a Blender mesh replaced the parts (the mesh itself is skipped,
	-- it has the same footprint).
	local S = LevelBuilder.CELL
	local buckets: { [number]: { BasePart } } = {}
	for _, root in blockers do
		for _, d in root:GetDescendants() do
			if not d:IsA("BasePart") or d:GetAttribute("Visual") or (d.Transparency >= 0.95 and not d.CanCollide) then
				continue
			end
			local cf, size = d.CFrame, d.Size
			local ext = (cf.RightVector * size.X):Abs() + (cf.UpVector * size.Y):Abs() + (cf.LookVector * size.Z):Abs()
			local lo, hi = cf.Position - ext / 2 - origin, cf.Position + ext / 2 - origin
			if hi.Y < 0.3 then
				continue -- puddles, papers, fallen tiles: loot can sit on those
			end
			local x0, x1 = math.max(1, math.floor(lo.X / S) + 1), math.min(layout.width, math.floor(hi.X / S) + 1)
			local z0, z1 = math.max(1, math.floor(lo.Z / S) + 1), math.min(layout.depth, math.floor(hi.Z / S) + 1)
			for x = x0, x1 do
				for z = z0, z1 do
					local k = x * 1000 + z
					local list = buckets[k]
					if not list then
						list = {}
						buckets[k] = list
					end
					table.insert(list, d)
				end
			end
		end
	end

	-- Is the item's footprint free of every part near it? `at` is where
	-- its centre would be; `bottom` the world height of its underside.
	-- Measured from just above what it rests on, so the floor clutter or
	-- the shelf under it doesn't count.
	local floorY = origin.Y
	local function clear(at: Vector3, handle: BasePart, bottom: number): boolean
		local s = handle.Size
		local r = math.sqrt(s.X * s.X + s.Z * s.Z) / 2 + 0.3
		local base = math.max(bottom + 0.1, floorY + 0.3)
		local h = math.max(bottom + s.Y - base, 0.4)
		local centre = Vector3.new(at.X, base + h / 2, at.Z)
		local cx, cz = LevelBuilder.cellOf(layout, centre, origin)
		for dx = -1, 1 do
			for dz = -1, 1 do
				for _, part in buckets[(cx + dx) * 1000 + cz + dz] or {} do
					local p = part.CFrame:PointToObjectSpace(centre)
					local half = part.Size / 2
					if math.abs(p.X) < half.X + r and math.abs(p.Y) < half.Y + h / 2 and math.abs(p.Z) < half.Z + r then
						return false
					end
				end
			end
		end
		return true
	end

	-- Off the floor (on a shelf): is there still something flat right under
	-- it? After a Shift the rack may be gone, leaving it floating.
	local function supported(at: Vector3, bottom: number): boolean
		if bottom < floorY + 0.4 then
			return true
		end
		local cx, cz = LevelBuilder.cellOf(layout, at, origin)
		for _, part in buckets[cx * 1000 + cz] or {} do
			local p = part.CFrame:PointToObjectSpace(Vector3.new(at.X, bottom, at.Z))
			local half = part.Size / 2
			if math.abs(p.X) < half.X and math.abs(p.Z) < half.Z and p.Y > half.Y - 0.35 and p.Y < half.Y + 0.35 then
				return true
			end
		end
		return false
	end

	-- Spots in a cell, nearest to `from` first, kept clear of the walls.
	local grid = {}
	for i = -4, 4 do
		for j = -4, 4 do
			table.insert(grid, Vector3.new(i * 1.75, 0, j * 1.75))
		end
	end
	local function spots(x: number, z: number, from: Vector3): { Vector3 }
		local c = LevelBuilder.cellCenter(x, z, origin)
		local list = {}
		for _, o in grid do
			table.insert(list, c + o)
		end
		table.sort(list, function(a, b)
			return (a - from).Magnitude < (b - from).Magnitude
		end)
		return list
	end

	local total, moved, stuck = 0, 0, 0
	for _, tool in folder:GetChildren() do
		local handle = tool:IsA("Tool") and tool:FindFirstChild("Handle") :: BasePart?
		if not handle then
			continue
		end
		total += 1
		local pos = handle.Position
		local bottom = pos.Y - handle.Size.Y / 2
		if LevelBuilder.inLevel(layout, pos, origin) and supported(pos, bottom) and clear(pos, handle, bottom) then
			continue
		end
		-- Breadth-first out from its cell through open walls.
		local sx, sz = LevelBuilder.cellOf(layout, pos, origin)
		local seen = { [sx * 1000 + sz] = true }
		local queue = { { sx, sz } }
		local head, found = 1, nil
		while head <= #queue and head <= 40 and not found do
			local x, z = queue[head][1], queue[head][2]
			head += 1
			for _, spot in spots(x, z, pos) do
				if clear(spot, handle, floorY + 0.05) then -- moved items go on the floor
					found = spot
					break
				end
			end
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local nx, nz = x + d[1], z + d[2]
				local k = nx * 1000 + nz
				if nx >= 1 and nz >= 1 and nx <= layout.width and nz <= layout.depth and not seen[k] and not LevelGen.hasWall(layout, x, z, d[1], d[2]) then
					seen[k] = true
					table.insert(queue, { nx, nz })
				end
			end
		end
		if found then
			local _, yaw, _ = handle.CFrame:ToOrientation()
			handle.CFrame = CFrame.new(found.X, handle.Size.Y / 2 + 0.05, found.Z) * CFrame.Angles(0, yaw, 0)
			moved += 1
		else
			stuck += 1
		end
	end
	return total, moved, stuck
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
	-- Three studs in front of you, but never through a wall or into a prop
	-- (it would be inside it or on the far side, and look like it vanished).
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	local level = folder.Parent
	local reach = 3
	local structure = level and level:FindFirstChild("Structure")
	if structure then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { structure }
		local from = Vector3.new(root.Position.X, 1, root.Position.Z)
		local hit = workspace:Raycast(from, look * 4.5, params)
		if hit then
			reach = math.max(0, (hit.Position - from).Magnitude - 1.5)
		end
	end
	local pos = root.Position + look * reach
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
