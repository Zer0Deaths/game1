--!strict
-- THE QUIET: SHIFT's third entity, and the only one with no body. It lives
-- in the fluorescent hum. Every so often the hum dies in a ring of cells
-- around one player (every cell within Config.QUIET.radiusCells of theirs):
--   falling  the hum drains away and the tubes in the ring dim
--            (warnSeconds). This is the tell; moving is still safe.
--   silent   dead silence for silentMin-silentMax seconds, and one slow
--            inhale close by. Anyone in the ring who makes a sound is taken:
--            walking, sprinting, jumping, dropping loot. Standing still and
--            looking around are safe. Then the hum comes back.
-- The safehouse note warns about it: "if the hum stops / STOP".
--
-- Its rule never fights another entity's:
--   * never during a Shift (warning or blackout) or while the Foreman is
--     switching the level off; twice as likely in the minute after a
--     Shift, but not in the first seconds of light,
--   * holds off while a Tenant is noticing or chasing anyone (and lets go
--     if one starts), and never picks a player a Tenant is close to,
--   * never rings a light Lampjaw is in (Lampjaw also stays out of the ring),
--   * the lift is always safe.
--
-- One per crew level (Sublevels creates it). It stays dormant above
-- Config.QUIET.fromDepth unless forced (Workspace attribute ForceQuiet,
-- for Studio testing).
-- State for clients (the crew's CrewState, mirrored onto Workspace):
--   QuietState   "idle" | "falling" | "silent"
--   QuietCell    cell key (x * 1000 + z) at the centre of the ring, 0 when idle
--   QuietRadius  the ring's radius in cells

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local NoiseService = require(script.Parent:WaitForChild("NoiseService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local Q = Config.QUIET
local TICK = 0.1
local JUMP_SPEED = 6 -- studs/s up or down: you're off the floor, and you'll land loud

local Quiet = {}

export type Quiet = { destroy: () -> (), force: () -> () }

-- Is cell key `a` within `radius` cells of cell key `b` (a square ring)?
function Quiet.within(a: number, b: number, radius: number): boolean
	return math.abs(a // 1000 - b // 1000) <= radius and math.abs(a % 1000 - b % 1000) <= radius
end

function Quiet.create(ctx: any): Quiet
	local state: Folder = ctx.state
	local alive = true
	local phase = "idle"
	local centre = 0
	local phaseEnds = 0
	local silentSince = 0
	local nextAt = os.clock() + Q.firstDelay
	local lastLight = -math.huge -- os.clock() the last Shift blackout ended
	local wasShifting = false
	local forced = false
	local moving: { [Player]: number } = {}

	local function publish()
		state:SetAttribute("QuietState", phase)
		state:SetAttribute("QuietCell", centre)
		state:SetAttribute("QuietRadius", Q.radiusCells)
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

	local function inLift(r: BasePart): boolean
		local offset = r.Position - (ctx.lift :: Vector3)
		return Vector3.new(offset.X, 0, offset.Z).Magnitude <= Config.LIFT_RADIUS and math.abs(offset.Y) < 8
	end

	local function keyOf(r: BasePart): number
		local x, z = LevelBuilder.cellOf(ctx.layout, r.Position, ctx.origin)
		return x * 1000 + z
	end

	local function tenants(): { Model }
		local out: { Model } = {}
		for _, t in CollectionService:GetTagged("SHIFT_Tenant") do
			if t:IsA("Model") and t:GetAttribute("Crew") == ctx.crew and t:IsDescendantOf(workspace) then
				table.insert(out, t)
			end
		end
		return out
	end

	local function hunting(): boolean
		for _, t in tenants() do
			local s = t:GetAttribute("State")
			if s == "notice" or s == "chase" then
				return true
			end
		end
		return false
	end

	local function tenantNear(pos: Vector3): boolean
		for _, t in tenants() do
			local d = t:GetPivot().Position - pos
			if Vector3.new(d.X, 0, d.Z).Magnitude <= Q.tenantClearance then
				return true
			end
		end
		return false
	end

	local function finish(now: number)
		if phase ~= "idle" then
			print(`[Quiet] crew {ctx.crew}: the hum is back`)
		end
		phase = "idle"
		centre = 0
		table.clear(moving)
		publish()
		nextAt = now + Q.restMin
	end

	-- Pick someone to ring. Returns false (and why) if nobody fits right now.
	local function begin(now: number): (boolean, string)
		if hunting() then
			return false, "a Tenant is hunting"
		end
		local lampjaw = (state:GetAttribute("LampjawCell") or 0) :: number
		local options: { { player: Player, key: number } } = {}
		for _, p in Players:GetPlayers() do
			local r = rootOf(p)
			if r and not inLift(r) and not tenantNear(r.Position) then
				local key = keyOf(r)
				if lampjaw == 0 or not Quiet.within(lampjaw, key, Q.radiusCells) then
					table.insert(options, { player = p, key = key })
				end
			end
		end
		if #options == 0 then
			return false, "nobody in the level clear of the Tenant, Lampjaw and the lift"
		end
		local pick = options[math.random(1, #options)]
		centre = pick.key
		phase = "falling"
		phaseEnds = now + Q.warnSeconds
		table.clear(moving)
		publish()
		-- The first time each player meets it, tell them the rule while
		-- moving is still safe. After that the hum is the only warning.
		for _, p in Players:GetPlayers() do
			local r = rootOf(p)
			if r and Quiet.within(keyOf(r), centre, Q.radiusCells) and not p:GetAttribute("QuietTaught") then
				p:SetAttribute("QuietTaught", true)
				Remotes.Notify:FireClient(p, "The hum has stopped. Don't move.", "warn")
			end
		end
		print(`[Quiet] crew {ctx.crew}: the hum stops around {pick.player.Name} (cell {centre // 1000},{centre % 1000})`)
		return true, ""
	end

	local function take(player: Player)
		local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		humanoid.Health = 0
		moving[player] = nil
		ctx.notify(`{player.DisplayName} made a sound in the quiet.`, "warn")
		print(`[Quiet] crew {ctx.crew}: took {player.Name}`)
	end

	-- The silence: anyone in the ring who makes a sound is taken. A twitch
	-- (under Q.tolerance seconds of movement in all) is let go; dropping
	-- loot never is.
	local function listen()
		for _, p in Players:GetPlayers() do
			local r = rootOf(p)
			if not r or inLift(r) or not Quiet.within(keyOf(r), centre, Q.radiusCells) then
				continue
			end
			if NoiseService.madeSince(p, silentSince) then
				take(p)
			elseif NoiseService.playerRadius(p) > 0 or math.abs(r.AssemblyLinearVelocity.Y) > JUMP_SPEED then
				moving[p] = (moving[p] or 0) + TICK
				if (moving[p] :: number) >= Q.tolerance then
					take(p)
				end
			end
		end
	end

	local function tick()
		local now = os.clock()
		local playing = state:GetAttribute("State") == "playing"
		local shifting = state:GetAttribute("Shifting") == true
		if wasShifting and not shifting then
			lastLight = now
		end
		wasShifting = shifting
		-- The Foreman says move; the Quiet would say freeze. Never both.
		local shift = shifting or state:GetAttribute("ShiftWarning") == true or state:GetAttribute("ForemanActive") == true

		if phase ~= "idle" then
			-- Let go if anything else takes over: the Shift, a hunt, the end.
			if not playing or shift or hunting() then
				finish(now)
			elseif now >= phaseEnds then
				if phase == "falling" then
					phase = "silent"
					silentSince = now
					phaseEnds = now + Q.silentMin + math.random() * (Q.silentMax - Q.silentMin)
					table.clear(moving)
					publish()
				else
					finish(now)
				end
			elseif phase == "silent" then
				listen()
			end
			return
		end

		if not playing or shift or now < nextAt or now - lastLight < Q.afterShiftGrace then
			return
		end
		if forced then
			forced = false
			local ok, why = begin(now)
			if not ok then
				print(`[Quiet] crew {ctx.crew}: forced, but {why}`)
			end
			return
		end
		if ctx.depth < Q.fromDepth then
			return
		end
		-- A steady chance each tick (on average Q.meanWait seconds once it
		-- can strike), doubled in the minute after the lights come back.
		local rate = TICK / Q.meanWait * (if now - lastLight < Q.afterShiftWindow then 2 else 1)
		if math.random() < rate then
			begin(now)
		end
	end

	publish()
	local conn = Players.PlayerRemoving:Connect(function(player)
		moving[player] = nil
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
			phase = "idle"
			centre = 0
			publish()
		end,
		force = function()
			if phase == "idle" then
				forced = true
				nextAt = 0
			end
		end,
	}
end

return Quiet
