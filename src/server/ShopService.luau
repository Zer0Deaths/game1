--!strict
-- ShopService: buying from the safehouse counter, and what items do.
-- Owned items are Player attributes, so the client UI and other systems
-- can read them:
--   Own_<id>  number  level of a permanent item (0 = not owned)
--   Run_<id>  bool    a one-run item waiting for (or in use on) a run
--   CarryBonus, Battery (0-100), FlashlightOn
-- Purchases only work in the safehouse, and the server checks the price.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShopItems = require(Shared:WaitForChild("ShopItems"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local ShopService = {}

local byId: { [string]: ShopItems.Item } = {}
for _, item in ShopItems do
	byId[item.id] = item
end

local inUse: { [Player]: { string } } = {} -- one-run items active this run

local function inSafehouse(player: Player): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and root.Position.X < 0 -- the level starts at X = 0, the safehouse is well west of it
end

local function flashlightOf(player: Player): SpotLight?
	local head = player.Character and player.Character:FindFirstChild("Head")
	return head and head:FindFirstChild("Flashlight") :: SpotLight?
end

local function setFlashlight(player: Player, on: boolean)
	player:SetAttribute("FlashlightOn", on)
	local light = flashlightOf(player)
	if light then
		light.Enabled = on
	end
end

-- Make the character match what the player owns.
function ShopService.apply(player: Player)
	player:SetAttribute("CarryBonus", (player:GetAttribute("Own_bigpack") or 0) :: number)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if head and (player:GetAttribute("Own_flashlight") or 0) > 0 and not head:FindFirstChild("Flashlight") then
		local light = Instance.new("SpotLight")
		light.Name = "Flashlight"
		light.Face = Enum.NormalId.Front
		light.Angle = 55
		light.Range = Config.FLASHLIGHT_RANGE
		light.Brightness = Config.FLASHLIGHT_BRIGHTNESS
		light.Color = Color3.fromRGB(255, 246, 220)
		light.Shadows = false
		light.Enabled = false
		light.Parent = head
	end
	setFlashlight(player, false)
end

local function buy(player: Player, id: unknown)
	local item = if typeof(id) == "string" then byId[id] else nil
	if not item then
		return
	end
	if not inSafehouse(player) then
		Remotes.Notify:FireClient(player, "The shop is in the safehouse.", "warn")
		return
	end
	local price: number
	if item.kind == "permanent" then
		local level = (player:GetAttribute(`Own_{item.id}`) or 0) :: number
		if level >= #item.price then
			Remotes.Notify:FireClient(player, `You already have the best {item.name}.`, "warn")
			return
		end
		price = item.price[level + 1]
	else
		if player:GetAttribute(`Run_{item.id}`) then
			Remotes.Notify:FireClient(player, `You already have {item.name} for the next run.`, "warn")
			return
		end
		price = item.price[1]
	end
	local cash = (player:GetAttribute("Cash") or 0) :: number
	if cash < price then
		Remotes.Notify:FireClient(player, `Not enough cash: {item.name} costs ${price}.`, "warn")
		return
	end
	player:SetAttribute("Cash", cash - price)
	if item.kind == "permanent" then
		player:SetAttribute(`Own_{item.id}`, ((player:GetAttribute(`Own_{item.id}`) or 0) :: number) + 1)
	else
		player:SetAttribute(`Run_{item.id}`, true)
	end
	ShopService.apply(player)
	Remotes.Notify:FireClient(player, `Bought {item.name} for ${price}.`, "money")
end

function ShopService.init()
	Remotes.BuyItem.OnServerEvent:Connect(buy)
	Remotes.ToggleFlashlight.OnServerEvent:Connect(function(player)
		if (player:GetAttribute("Own_flashlight") or 0) == 0 then
			return
		end
		local on = not player:GetAttribute("FlashlightOn")
		if on and ((player:GetAttribute("Battery") or 0) :: number) <= 0 then
			Remotes.Notify:FireClient(player, "Flashlight battery is flat.", "warn")
			return
		end
		setFlashlight(player, on)
	end)

	local function onPlayer(player: Player)
		player:SetAttribute("Battery", 100)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 10)
			ShopService.apply(player)
		end)
		if player.Character then
			ShopService.apply(player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		inUse[p] = nil
	end)

	-- Battery drains while the flashlight is on.
	task.spawn(function()
		local drain = 100 / Config.FLASHLIGHT_SECONDS
		while true do
			task.wait(1)
			for _, p in Players:GetPlayers() do
				if p:GetAttribute("FlashlightOn") then
					local b = math.max(0, ((p:GetAttribute("Battery") or 0) :: number) - drain)
					p:SetAttribute("Battery", b)
					if b <= 0 then
						setFlashlight(p, false)
						Remotes.Notify:FireClient(p, "Flashlight battery died.", "warn")
					end
				end
			end
		end
	end)
end

-- A crew drops into its first sublevel: one-run items are locked in and
-- the flashlight battery is topped up.
function ShopService.startRun(players: { Player })
	for _, p in players do
		local list = {}
		for _, item in ShopItems do
			if item.kind == "run" and p:GetAttribute(`Run_{item.id}`) then
				table.insert(list, item.id)
			end
		end
		inUse[p] = list
		p:SetAttribute("Battery", 100)
	end
end

-- A crew is back in the safehouse (returned or wiped): one-run items are
-- used up and the flashlight goes off.
function ShopService.endRun(players: { Player })
	for _, p in players do
		for _, id in inUse[p] or {} do
			p:SetAttribute(`Run_{id}`, nil)
		end
		inUse[p] = nil
		p:SetAttribute("Battery", 100)
		setFlashlight(p, false)
	end
end

-- A wiped crew loses everything it bought (Config.WIPE_LOSES_KIT).
function ShopService.wipeKit(player: Player)
	for _, item in ShopItems do
		player:SetAttribute(`Own_{item.id}`, nil)
		player:SetAttribute(`Run_{item.id}`, nil)
	end
	inUse[player] = nil
	setFlashlight(player, false)
	ShopService.apply(player)
end

return ShopService
