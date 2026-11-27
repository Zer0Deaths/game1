--!strict
-- DataService: saves each player's progress with Roblox DataStores:
-- Cash, permanent shop items, and lifetime stats (see PlayerData.luau).
-- Loads on join, saves on leave, after every run, every 2 minutes, and when
-- the server shuts down. If loading fails, that player's progress is NOT
-- saved for the session, so a hiccup can never wipe a real save.
-- In Studio this needs "Enable Studio Access to API Services" (see TODO.md);
-- without it the game still runs, it just doesn't save.
-- Also shows Cash and Quotas met on the player list.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerData"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))

local DataService = {}

local STORE_NAME = "SHIFT_Players_v1"
local okStore, store = pcall(function()
	return DataStoreService:GetDataStore(STORE_NAME)
end)
if not okStore then
	warn("[Data] DataStores unavailable, progress will not save:", store)
end

local loaded: { [Player]: boolean } = {}
local studioOffline = false -- Studio without API access: play with a fresh, unsaved profile

local function studioBlocked(err: string): boolean
	return RunService:IsStudio() and string.find(err, "StudioAccessToApisNotAllowed", 1, true) ~= nil
end

local function key(player: Player): string
	return `p_{player.UserId}`
end

local function withRetries<T>(fn: () -> T): (boolean, T | string)
	local lastErr: any = nil
	for attempt = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(attempt)
	end
	return false, tostring(lastErr)
end

local function leaderstats(player: Player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = folder
	local quotas = Instance.new("IntValue")
	quotas.Name = "Quotas"
	quotas.Parent = folder
	folder.Parent = player
	local function sync()
		cash.Value = (player:GetAttribute("Cash") or 0) :: number
		quotas.Value = (player:GetAttribute("Stat_QuotasMet") or 0) :: number
	end
	player:GetAttributeChangedSignal("Cash"):Connect(sync)
	player:GetAttributeChangedSignal("Stat_QuotasMet"):Connect(sync)
	sync()
end

local function load(player: Player)
	leaderstats(player)
	if not okStore or studioOffline then
		for name, value in PlayerData.deserialize(nil) do
			player:SetAttribute(name, value)
		end
		return
	end
	-- One quick try first, so Studio without API access doesn't spam retries.
	local ok, result = pcall(function()
		return (store :: DataStore):GetAsync(key(player))
	end)
	if not ok and studioBlocked(tostring(result)) then
		studioOffline = true
		warn("[Data] Studio has no API access, so progress won't save in this test. (Fine for testing; see TODO.md to turn it on.)")
		for name, value in PlayerData.deserialize(nil) do
			player:SetAttribute(name, value)
		end
		return
	end
	if not ok then
		ok, result = withRetries(function()
			return (store :: DataStore):GetAsync(key(player))
		end)
	end
	if not player.Parent then
		return
	end
	if not ok then
		warn(`[Data] could not load {player.Name}: {result}`)
		Remotes.Notify:FireClient(player, "Couldn't load your progress. It won't be saved this session.", "warn")
		return
	end
	for name, value in PlayerData.deserialize(result) do
		player:SetAttribute(name, value)
	end
	loaded[player] = true
	ShopService.apply(player)
	print(`[Data] loaded {player.Name}: ${player:GetAttribute("Cash")}`)
end

function DataService.save(player: Player)
	if not okStore or not loaded[player] then
		return
	end
	local data = PlayerData.serialize(function(name)
		return player:GetAttribute(name)
	end)
	local ok, err = withRetries(function()
		return (store :: DataStore):SetAsync(key(player), data, { player.UserId })
	end)
	if not ok then
		warn(`[Data] could not save {player.Name}: {err}`)
	end
end

function DataService.saveAll()
	for _, p in Players:GetPlayers() do
		task.spawn(DataService.save, p)
	end
end

function DataService.init()
	-- Make sure every saved field exists (as its default) before loading.
	local function onPlayer(player: Player)
		for name, default in PlayerData.FIELDS do
			if player:GetAttribute(name) == nil then
				player:SetAttribute(name, default)
			end
		end
		task.spawn(load, player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		DataService.save(player)
		loaded[player] = nil
	end)
	game:BindToClose(function()
		local pending = 0
		for _, p in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				DataService.save(p)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.2)
		end
	end)
	-- Checkpoints: Sublevels saves a crew whenever a sublevel is cleared or
	-- the crew is wiped, and everyone is saved every 2 minutes.
	task.spawn(function()
		while true do
			task.wait(120)
			DataService.saveAll()
		end
	end)
end

return DataService
