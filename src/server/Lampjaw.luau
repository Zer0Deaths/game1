--!strict
-- LAMPJAW: SHIFT's second entity. It lives inside the flickering light
-- fittings. Every so often it slips into one flickering light near a
-- player: that light strobes red and buzzes (done on each player's device,
-- see main.client). Stand under it too long and it takes you; your loot
-- spills where you were. It is more active while the Shift is coming.
-- Counter: watch the lights, move fast, never stop under a red flicker.
-- Its body (EntityRig) hangs out of the fitting it's in: a thin black
-- neck and a long jaw. Clients only show it in the red flashes, so it's
-- glimpsed, never seen clearly. Its one cue is an electrical crackle
-- with chattering teeth (Cues.client).
--
-- One per crew level from Config.DEPTH.lampjawFrom (Sublevels creates it).
-- State for clients: the crew's CrewState attribute "LampjawCell" = the
-- cell key (x * 1000 + z) of the light it's in, or 0.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local EntityRig = require(script.Parent:WaitForChild("EntityRig"))

local L = Config.LAMPJAW
local TICK = 0.1

local Lampjaw = {}

export type Lampjaw = { destroy: () -> () }

function Lampjaw.create(ctx: any): Lampjaw
	local state: Folder = ctx.state
	local alive = true
	local cellKey = 0
	local holdUntil = 0
	local nextPossess = 0
	local dwell: { [Player]: number } = {}

	local body = EntityRig.build("Lampjaw")
	body:SetAttribute("Crew", ctx.crew)
	body.Parent = ServerStorage

	local function setCell(key: number)
		cellKey = key
		state:SetAttribute("LampjawCell", key)
		table.clear(dwell)
		if key == 0 then
			body.Parent = ServerStorage
		else
			-- Hang it from the fitting, facing a random way.
			local c = LevelBuilder.cellCenter(key // 1000, key % 1000, ctx.origin)
			body:PivotTo(CFrame.new(c.X, c.Y + LevelBuilder.HEIGHT - 0.45, c.Z) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
			body:SetAttribute("Cell", key)
			body.Parent = workspace
		end
	end

	local function rootOf(player: Player): BasePart?
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local r = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and humanoid.Health > 0 and r and LevelBuilder.inLevel(ctx.layout, r.Position, ctx.origin) then
			return r
		end
		return nil
	end

	local function rest(now: number)
		local nearShift = state:GetAttribute("ShiftWarning") == true
		nextPossess = now + (if nearShift then L.restNearShift else L.restMin + math.random() * (L.restMax - L.restMin))
	end

	local function possess(now: number)
		local l = ctx.layout
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
		local cx, cz = LevelBuilder.cellOf(l, r.Position, ctx.origin)
		local dist = LevelGen.distancesFrom(l, cx, cz)
		-- Never a light inside the Quiet's ring: you can't be told to freeze
		-- and to move at once.
		local quietCell = if state:GetAttribute("QuietState") ~= "idle" then (state:GetAttribute("QuietCell") or 0) :: number else 0
		local quietRadius = (state:GetAttribute("QuietRadius") or 1) :: number
		local near: { number } = {}
		for key, d in dist do
			local cell = l.cells[key // 1000][key % 1000]
			local inRing = quietCell ~= 0
				and math.abs(key // 1000 - quietCell // 1000) <= quietRadius
				and math.abs(key % 1000 - quietCell % 1000) <= quietRadius
			if cell.light == "flicker" and d >= 1 and d <= L.nearCells and not inRing then
				table.insert(near, key)
			end
		end
		if #near == 0 then
			rest(now)
			return
		end
		local chosen = near[math.random(1, #near)]
		setCell(chosen)
		print(`[Lampjaw] crew {ctx.crew}: in the light at {chosen // 1000},{chosen % 1000}`)
		holdUntil = now + L.holdMin + math.random() * (L.holdMax - L.holdMin)
	end

	local function tick()
		local now = os.clock()
		local l = ctx.layout
		if not alive or state:GetAttribute("State") ~= "playing" or state:GetAttribute("Shifting") then
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
		local centre = LevelBuilder.cellCenter(cellKey // 1000, cellKey % 1000, ctx.origin)
		local limit = if state:GetAttribute("ShiftWarning") then L.grabAfterNearShift else L.grabAfter
		for _, player in Players:GetPlayers() do
			local r = rootOf(player)
			local d = r and (r.Position - centre)
			if d and Vector3.new(d.X, 0, d.Z).Magnitude <= L.reach then
				dwell[player] = (dwell[player] or 0) + TICK
				if dwell[player] >= limit then
					local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
					body:SetAttribute("AttackAt", workspace:GetServerTimeNow()) -- clients play the bite
					humanoid.Health = 0
					ctx.notify(`{player.DisplayName} lingered under the wrong light.`, "warn")
					print(`[Lampjaw] crew {ctx.crew}: took {player.Name}`)
					task.delay(0.6, function()
						if cellKey == 0 then
							body.Parent = ServerStorage
						end
					end)
					cellKey = 0
					state:SetAttribute("LampjawCell", 0)
					table.clear(dwell)
					rest(now)
					return
				end
			else
				dwell[player] = nil
			end
		end
	end


	setCell(0)
	rest(os.clock())
	local conn = Players.PlayerRemoving:Connect(function(player)
		dwell[player] = nil
	end)
	task.spawn(function()
		while alive do
			task.wait(TICK)
			if alive then
				tick()
			end
		end
	end)
	return {
		destroy = function()
			alive = false
			conn:Disconnect()
			state:SetAttribute("LampjawCell", 0)
			body:Destroy()
		end,
	}
end

return Lampjaw
