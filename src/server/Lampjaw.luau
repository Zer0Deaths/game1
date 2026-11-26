--!strict
-- LAMPJAW: SHIFT's second entity. It lives inside the flickering light
-- fittings. Every so often it slips into one flickering light near a
-- player: that light strobes red and buzzes (done on each player's device,
-- see main.client). Stand under it too long and it takes you; your loot
-- spills where you were. It is more active while the Shift is coming.
-- Counter: watch the lights, move fast, never stop under a red flicker.
--
-- State for clients: Workspace attribute "LampjawCell" = the cell key
-- (x * 1000 + z) of the light it's in, or 0.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local L = Config.LAMPJAW
local TICK = 0.1

local Lampjaw = {}

local layout: LevelGen.Layout? = nil
local cellKey = 0
local holdUntil = 0
local nextPossess = 0
local dwell: { [Player]: number } = {}

local function setCell(key: number)
	cellKey = key
	workspace:SetAttribute("LampjawCell", key)
	table.clear(dwell)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end
	return nil
end

local function rest(now: number)
	local nearShift = workspace:GetAttribute("ShiftWarning") == true
	nextPossess = now + (if nearShift then L.restNearShift else L.restMin + math.random() * (L.restMax - L.restMin))
end

local function possess(now: number)
	local l = layout
	if not l then
		return
	end
	local living: { BasePart } = {}
	for _, player in Players:GetPlayers() do
		local r = rootOf(player)
		if r then
			table.insert(living, r)
		end
	end
	if #living == 0 then
		return
	end
	local r = living[math.random(1, #living)]
	local cx = math.clamp(math.floor(r.Position.X / LevelBuilder.CELL) + 1, 1, l.width)
	local cz = math.clamp(math.floor(r.Position.Z / LevelBuilder.CELL) + 1, 1, l.depth)
	local dist = LevelGen.distancesFrom(l, cx, cz)
	local near: { number } = {}
	for key, d in dist do
		local cell = l.cells[key // 1000][key % 1000]
		if cell.light == "flicker" and d >= 1 and d <= L.nearCells then
			table.insert(near, key)
		end
	end
	if #near == 0 then
		rest(now)
		return
	end
	setCell(near[math.random(1, #near)])
	holdUntil = now + L.holdMin + math.random() * (L.holdMax - L.holdMin)
end

local function tick()
	local now = os.clock()
	local l = layout
	if not l or workspace:GetAttribute("RunState") ~= "playing" or workspace:GetAttribute("Shifting") then
		if cellKey ~= 0 then
			setCell(0)
			rest(now)
		end
		return
	end
	if cellKey == 0 then
		if now >= nextPossess then
			possess(now)
		end
		return
	end
	-- The Shift may have re-rolled this light into a normal one.
	local cell = l.cells[cellKey // 1000][cellKey % 1000]
	if now >= holdUntil or cell.light ~= "flicker" then
		setCell(0)
		rest(now)
		return
	end
	local centre = LevelBuilder.cellCenter(cellKey // 1000, cellKey % 1000)
	local limit = if workspace:GetAttribute("ShiftWarning") then L.grabAfterNearShift else L.grabAfter
	for _, player in Players:GetPlayers() do
		local r = rootOf(player)
		local d = r and (r.Position - centre)
		if d and Vector3.new(d.X, 0, d.Z).Magnitude <= L.reach then
			dwell[player] = (dwell[player] or 0) + TICK
			if dwell[player] >= limit then
				local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
				humanoid.Health = 0
				Remotes.Notify:FireAllClients(`{player.DisplayName} lingered under the wrong light.`, "warn")
				print(`[Lampjaw] took {player.Name}`)
				setCell(0)
				rest(now)
				return
			end
		else
			dwell[player] = nil
		end
	end
end

function Lampjaw.setLevel(newLayout: LevelGen.Layout)
	layout = newLayout
	setCell(0)
	rest(os.clock())
end

function Lampjaw.init()
	workspace:SetAttribute("LampjawCell", 0)
	if not L.enabled then
		return
	end
	task.spawn(function()
		while true do
			task.wait(TICK)
			tick()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		dwell[player] = nil
	end)
end

return Lampjaw
