--!strict
-- Sublevels: the crew loop. Every crew runs on its own.
--
--   Safehouse  The crew presses Ready at the descent lift. When everyone in
--              the crew is ready, a short countdown, then the crew drops
--              into sublevel 1 of its own level.
--   Sublevel   A level built just for this crew (at its own origin, far
--              from the others). The crew deposits loot at the exit lift
--              towards one crew quota. Quota met: the lift turns green.
--              When everyone alive is aboard, the panel offers
--                Go deeper            next sublevel: bigger quota, loot
--                                     worth more, more danger. Dead crew
--                                     members come back for it.
--                Return to safehouse  bank it, shop, start again from 1.
--              Either way the bank is split evenly as Cash.
--   Wipe       Time runs out before the crew leaves, or everyone in the
--              level is dead: the crew is wiped. Loot is lost and, with
--              Config.WIPE_LOSES_KIT, everything bought in the shop too.
--
-- Live state for each crew's devices is on CrewState folders.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Crews = require(Shared:WaitForChild("Crews"))
local CrewState = require(Shared:WaitForChild("CrewState"))
local LevelGen = require(Shared:WaitForChild("LevelGen"))
local LevelTypes = require(Shared:WaitForChild("LevelTypes"))
local LevelBuilder = require(script.Parent:WaitForChild("LevelBuilder"))
local ArtefactService = require(script.Parent:WaitForChild("ArtefactService"))
local CrewService = require(script.Parent:WaitForChild("CrewService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ExitLift = require(script.Parent:WaitForChild("ExitLift"))
local Lampjaw = require(script.Parent:WaitForChild("Lampjaw"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local ShiftService = require(script.Parent:WaitForChild("ShiftService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local Tenant = require(script.Parent:WaitForChild("Tenant"))

local Sublevels = {}

type Ctx = {
	crew: number,
	depth: number,
	origin: Vector3,
	layout: LevelGen.Layout,
	model: Model,
	state: Folder,
	lift: Vector3,
	liftModel: Model?,
	artefacts: Folder,
	shift: ShiftService.Shift?,
	tenants: { Tenant.Tenant },
	lampjaw: Lampjaw.Lampjaw?,
	map: MapService.CrewMap?,
	startedAt: number,
	alive: boolean,
	leaving: boolean,
	notify: (string, string) -> (),
}

local active: { [number]: Ctx } = {}
local sendToHub: (Player, number) -> () = function() end

local function now(): number
	return workspace:GetServerTimeNow()
end

function Sublevels.origin(crew: number): Vector3
	-- Well away from the safehouse (which sits at negative X) and from
	-- each other, so streaming never sends players another crew's level.
	return Vector3.new(1000 + (crew - 1) * Config.LEVEL_SPACING, 0, 0)
end

function Sublevels.state(crew: number): Folder
	return CrewState.folder(crew)
end

function Sublevels.active(crew: number): boolean
	return active[crew] ~= nil
end

local function notifyCrew(crew: number, text: string, kind: string)
	for _, p in CrewService.members(crew) do
		Remotes.Notify:FireClient(p, text, kind)
	end
end

local function aliveRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end
	return nil
end

local function inLevel(ctx: Ctx, player: Player): BasePart?
	local r = aliveRoot(player)
	if r and LevelBuilder.inLevel(ctx.layout, r.Position, ctx.origin) then
		return r
	end
	return nil
end

local function inLift(ctx: Ctx, root: BasePart): boolean
	local offset = root.Position - ctx.lift
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= Config.LIFT_RADIUS and math.abs(offset.Y) < 8
end

-- The level a player is standing in, if any (for loot drops).
function Sublevels.levelFor(player: Player): Folder?
	local r = aliveRoot(player)
	local character = player.Character
	local pos = if r then r.Position else (character and character:GetPivot().Position)
	if not pos then
		return nil
	end
	for _, ctx in active do
		if LevelBuilder.inLevel(ctx.layout, pos, ctx.origin) then
			return ctx.artefacts
		end
	end
	return nil
end

local function spawnCFrame(ctx: Ctx, index: number): CFrame
	local c = LevelBuilder.cellCenter(ctx.layout.spawn.x, ctx.layout.spawn.z, ctx.origin)
	local angle = index * 2.4
	local r = 2 + (index % 4) * 1.5
	return CFrame.new(c + Vector3.new(math.cos(angle) * r, 4, math.sin(angle) * r))
end

-- Move a living player into the crew's level. Asks streaming for the area
-- first so they don't land before the floor exists on their device.
local function teleportIn(ctx: Ctx, player: Player, index: number)
	local r = aliveRoot(player)
	if not r then
		return
	end
	local cf = spawnCFrame(ctx, index)
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 10)
	end)
	if player.Character and aliveRoot(player) then
		(player.Character :: Model):PivotTo(cf)
	end
end

function Sublevels.join(player: Player): boolean
	local ctx = active[(player:GetAttribute("Crew") or 0) :: number]
	if not ctx or ctx.state:GetAttribute("State") ~= "playing" then
		return false
	end
	task.spawn(teleportIn, ctx, player, math.random(1, 16))
	return true
end

-- LIFT ------------------------------------------------------------------------

local clear: (Ctx, string) -> ()

local function hookLift(ctx: Ctx, model: Model)
	local deeper, surface = ExitLift.prompts(model)
	local function choose(player: Player, choice: string)
		if not ctx.alive or ctx.leaving or player:GetAttribute("Crew") ~= ctx.crew then
			return
		end
		local st = ctx.state
		if not st:GetAttribute("LiftReady") or st:GetAttribute("Aboard") ~= st:GetAttribute("Needed") then
			Remotes.Notify:FireClient(player, "Everyone alive has to be in the lift.", "warn")
			return
		end
		clear(ctx, choice)
	end
	deeper.Triggered:Connect(function(player)
		choose(player, "deeper")
	end)
	surface.Triggered:Connect(function(player)
		choose(player, "surface")
	end)
end

local function placeLift(ctx: Ctx)
	if ctx.liftModel then
		ctx.liftModel:Destroy()
	end
	local l = ctx.layout
	local pos, model = ExitLift.build(LevelBuilder.cellCenter(l.exit.x, l.exit.z, ctx.origin), LevelBuilder.HEIGHT, ctx.model)
	ctx.lift = pos
	ctx.liftModel = model
	ctx.state:SetAttribute("LiftPosition", pos)
	hookLift(ctx, model)
	if ctx.state:GetAttribute("LiftReady") then
		ExitLift.setReady(model, true, 0, 0)
	end
end

-- LIFECYCLE -------------------------------------------------------------------

local function destroy(ctx: Ctx)
	ctx.alive = false
	if ctx.shift then
		ctx.shift.destroy()
	end
	for _, t in ctx.tenants do
		t.destroy()
	end
	if ctx.lampjaw then
		ctx.lampjaw.destroy()
	end
	if ctx.map then
		ctx.map.destroy()
	end
	ctx.model:Destroy()
	if active[ctx.crew] == ctx then
		active[ctx.crew] = nil
	end
end

local function backToSafehouse(crew: number)
	local st = CrewState.folder(crew)
	st:SetAttribute("State", "hub")
	st:SetAttribute("Depth", 0)
	st:SetAttribute("LiftReady", false)
	st:SetAttribute("Banked", 0)
	st:SetAttribute("Quota", Crews.quota(1, math.max(1, #CrewService.members(crew)), Config.QUOTA_SOLO, Config.QUOTA_PER_EXTRA, Config.QUOTA_GROWTH))
	local members = CrewService.members(crew)
	for i, p in members do
		p:SetAttribute("Ready", false)
		p:SetAttribute("DiedThisRun", false)
		sendToHub(p, i)
	end
	ShopService.endRun(members)
	for _, p in members do
		task.spawn(DataService.save, p)
	end
end

-- Build sublevel `depth` for a crew and drop the whole crew into it.
local function start(crew: number, depth: number, seed: number?)
	local members = CrewService.members(crew)
	if #members == 0 then
		backToSafehouse(crew)
		return
	end
	local started = os.clock()
	local levelType = LevelTypes.pick(depth, math.random())
	local size = Crews.levelSize(#members, Config.LEVEL_SIZE_BY_CREW) + levelType.sizeBonus
	local gen = table.clone(levelType.gen) :: any
	gen.width, gen.depth = size, size
	local chosenSeed = seed or math.random(1, 999999)
	local layout = LevelGen.generate(chosenSeed, gen)
	local origin = Sublevels.origin(crew)
	LevelBuilder.setTheme(levelType.colours, levelType.materials, levelType.variants)
	local model = LevelBuilder.build(layout, workspace, origin, crew)
	local cells = layout.width * layout.depth
	local artefacts = ArtefactService.spawnAll(
		layout,
		model,
		function(x, z)
			return LevelBuilder.cellCenter(x, z, origin)
		end,
		math.floor(cells * Config.ARTEFACTS_PER_100_CELLS / 100),
		Crews.lootMultiplier(depth, Config.LOOT_VALUE_PER_DEPTH)
	)
	local st = CrewState.folder(crew)
	local quota = Crews.quota(depth, #members, Config.QUOTA_SOLO, Config.QUOTA_PER_EXTRA, Config.QUOTA_GROWTH)

	local ctx: Ctx = {
		crew = crew,
		depth = depth,
		origin = origin,
		layout = layout,
		model = model,
		state = st,
		lift = origin,
		liftModel = nil,
		artefacts = artefacts,
		shift = nil,
		tenants = {},
		lampjaw = nil,
		map = nil,
		startedAt = now(),
		alive = true,
		leaving = false,
		notify = function(text: string, kind: string)
			notifyCrew(crew, text, kind)
		end,
	}
	active[crew] = ctx

	st:SetAttribute("Depth", depth)
	st:SetAttribute("Quota", quota)
	st:SetAttribute("Banked", 0)
	st:SetAttribute("LiftReady", false)
	st:SetAttribute("Aboard", 0)
	st:SetAttribute("Needed", 0)
	st:SetAttribute("LevelName", levelType.name)
	st:SetAttribute("LightColour", levelType.light)
	st:SetAttribute("HazeColour", levelType.haze.colour)
	st:SetAttribute("HazeDecay", levelType.haze.decay)
	st:SetAttribute("HazeDensity", levelType.haze.density)
	st:SetAttribute("Tint", levelType.tint)
	st:SetAttribute("LevelSeed", chosenSeed)
	st:SetAttribute("LevelOrigin", origin)
	placeLift(ctx)

	ctx.shift = ShiftService.create(ctx, function()
		placeLift(ctx)
		ctx.notify("The lift has moved. Follow the compass.", "warn")
	end)
	if Config.TENANT.enabled then
		table.insert(ctx.tenants, Tenant.create(ctx))
		if depth >= Config.DEPTH.secondTenantFrom then
			table.insert(ctx.tenants, Tenant.create(ctx))
		end
	end
	if Config.LAMPJAW.enabled and depth >= Config.DEPTH.lampjawFrom then
		ctx.lampjaw = Lampjaw.create(ctx)
	end
	ctx.map = MapService.create(ctx)
	print(`[Level] crew {crew}, sublevel {depth}: {levelType.name} {layout.width}x{layout.depth}, seed {chosenSeed}, quota ${quota}, built in {math.round((os.clock() - started) * 1000)} ms`)

	-- Everyone in the crew comes down, including anyone who died on the
	-- sublevel before (they've been waiting in the safehouse).
	for i, p in members do
		p:SetAttribute("Ready", false)
		p:SetAttribute("DiedThisRun", false)
		p:SetAttribute("Stat_Deepest", math.max((p:GetAttribute("Stat_Deepest") or 0) :: number, depth))
		task.spawn(teleportIn, ctx, p, i)
	end
	if depth == 1 then
		ShopService.startRun(members)
	end
	st:SetAttribute("EndsAt", now() + Config.SUBLEVEL_SECONDS)
	st:SetAttribute("State", "playing")
	for _, p in members do
		local extra = if depth >= Config.DEPTH.secondTenantFrom
			then "  Two of them down here."
			elseif depth == Config.DEPTH.lampjawFrom then "  Watch the lights."
			else ""
		Remotes.Notify:FireClient(p, `SUBLEVEL {depth}: {string.upper(levelType.name)}. Crew quota ${quota}.{extra}`, "banner")
	end
end

clear = function(ctx: Ctx, choice: string)
	if ctx.leaving then
		return
	end
	ctx.leaving = true
	local st = ctx.state
	st:SetAttribute("State", "cleared")
	local crew, depth = ctx.crew, ctx.depth
	local members = CrewService.members(crew)
	local banked = (st:GetAttribute("Banked") or 0) :: number
	local quota = (st:GetAttribute("Quota") or 0) :: number
	local each = Crews.split(banked, #members)
	for _, p in members do
		ArtefactService.takeAll(p) -- loot doesn't carry between sublevels
		p:SetAttribute("Cash", ((p:GetAttribute("Cash") or 0) :: number) + each)
		p:SetAttribute("Stat_QuotasMet", ((p:GetAttribute("Stat_QuotasMet") or 0) :: number) + 1)
	end
	for _, p in members do
		task.spawn(DataService.save, p)
	end
	if choice == "deeper" then
		notifyCrew(crew, `SUBLEVEL {depth} CLEARED  ${banked} / ${quota}. Everyone takes ${each}. Going down...`, "banner")
		st:SetAttribute("DescendAt", now() + Config.DESCENT_COUNTDOWN)
		st:SetAttribute("State", "descending")
		task.wait(Config.DESCENT_COUNTDOWN)
		destroy(ctx)
		start(crew, depth + 1)
	else
		notifyCrew(crew, `SUBLEVEL {depth} CLEARED  ${banked} / ${quota}. Everyone takes ${each}. Back to the safehouse.`, "banner")
		task.wait(2)
		destroy(ctx)
		backToSafehouse(crew)
	end
end

local function wipe(ctx: Ctx, reason: string)
	if ctx.leaving then
		return
	end
	ctx.leaving = true
	local st = ctx.state
	st:SetAttribute("State", "wiped")
	local members = CrewService.members(ctx.crew)
	local kit = if Config.WIPE_LOSES_KIT then " All kit lost." else ""
	notifyCrew(ctx.crew, `CREW WIPED on sublevel {ctx.depth}: {reason}.{kit}`, "banner")
	print(`[Level] crew {ctx.crew} wiped on sublevel {ctx.depth}: {reason}`)
	for _, p in members do
		ArtefactService.takeAll(p)
		if Config.WIPE_LOSES_KIT then
			ShopService.wipeKit(p)
		end
	end
	task.wait(3)
	destroy(ctx)
	backToSafehouse(ctx.crew)
end

-- One pass over every active crew level: deposits, the lift, wipes.
local function tick()
	for crew, ctx in active do
		local st = ctx.state
		if st:GetAttribute("State") ~= "playing" or ctx.leaving then
			continue
		end
		local members = CrewService.members(crew)
		local living, aboard = 0, 0
		for _, p in members do
			local r = inLevel(ctx, p)
			if r then
				living += 1
				if inLift(ctx, r) then
					aboard += 1
					local total, count = ArtefactService.takeAll(p)
					if count > 0 then
						st:SetAttribute("Banked", ((st:GetAttribute("Banked") or 0) :: number) + total)
						p:SetAttribute("Stat_Deposited", ((p:GetAttribute("Stat_Deposited") or 0) :: number) + total)
						ctx.notify(`{p.DisplayName} deposited {count} item(s): +${total}`, "money")
					end
				end
			end
		end
		local banked = (st:GetAttribute("Banked") or 0) :: number
		local quota = (st:GetAttribute("Quota") or 0) :: number
		if not st:GetAttribute("LiftReady") and banked >= quota then
			st:SetAttribute("LiftReady", true)
			ctx.notify("QUOTA MET. Everyone alive, get in the lift.", "banner")
		end
		st:SetAttribute("Aboard", aboard)
		st:SetAttribute("Needed", living)
		if st:GetAttribute("LiftReady") and ctx.liftModel then
			ExitLift.setReady(ctx.liftModel, true, aboard, living)
			local deeper, surface = ExitLift.prompts(ctx.liftModel)
			local allIn = living > 0 and aboard == living
			deeper.Enabled = allIn
			surface.Enabled = allIn
		end
		-- Wipes. A few seconds' grace at the start while people stream in.
		if now() >= ((st:GetAttribute("EndsAt") or math.huge) :: number) then
			task.spawn(wipe, ctx, "out of time")
		elseif living == 0 and now() - ctx.startedAt > 8 then
			task.spawn(wipe, ctx, "nobody made it")
		end
	end
end

-- SAFEHOUSE ---------------------------------------------------------------------

-- Ready at the descent lift. The crew drops when everyone in it is ready.
function Sublevels.toggleReady(player: Player)
	local crew = (player:GetAttribute("Crew") or 1) :: number
	local st = CrewState.folder(crew)
	local state = st:GetAttribute("State")
	if state ~= "hub" and state ~= "countdown" then
		return
	end
	local ready = not player:GetAttribute("Ready")
	player:SetAttribute("Ready", ready)
	Remotes.Notify:FireClient(player, if ready then "Ready. Your crew drops when everyone in it is ready." else "Not ready.", "money")
end

local studioSeed: { [number]: number } = {}

local function hubTick(crew: number, seedOverride: number?)
	local st = CrewState.folder(crew)
	local state = st:GetAttribute("State")
	local members = CrewService.members(crew)
	if state ~= "hub" and state ~= "countdown" then
		return
	end
	local ready = 0
	for _, p in members do
		if p:GetAttribute("Ready") then
			ready += 1
		end
	end
	st:SetAttribute("ReadyCount", ready)
	st:SetAttribute("Quota", Crews.quota(1, math.max(1, #members), Config.QUOTA_SOLO, Config.QUOTA_PER_EXTRA, Config.QUOTA_GROWTH))
	local allReady = #members > 0 and ready == #members
	if state == "hub" and (allReady or seedOverride) then
		st:SetAttribute("State", "countdown")
		st:SetAttribute("DescendAt", now() + (if seedOverride then 0 else Config.DESCENT_COUNTDOWN))
	elseif state == "countdown" then
		if not allReady and not seedOverride then
			st:SetAttribute("State", "hub")
			notifyCrew(crew, "Descent cancelled: not everyone is ready.", "warn")
		elseif now() >= ((st:GetAttribute("DescendAt") or 0) :: number) then
			st:SetAttribute("State", "descending")
			studioSeed[crew] = nil
			task.spawn(start, crew, 1, seedOverride)
		end
	end
end

-- Studio testing: drop a crew straight into a seed.
function Sublevels.descendWithSeed(crew: number, seed: number)
	studioSeed[crew] = seed
end

function Sublevels.forceShift()
	for _, ctx in active do
		if ctx.shift then
			ctx.shift.force()
		end
	end
end

function Sublevels.init(hubSend: (Player, number) -> ())
	sendToHub = hubSend
	ArtefactService.setFolderResolver(Sublevels.levelFor)
	for c = 1, Config.CREW_COUNT do
		local st = CrewState.folder(c)
		st:SetAttribute("Name", Config.CREW_NAMES[c])
		st:SetAttribute("State", "hub")
		st:SetAttribute("Depth", 0)
		st:SetAttribute("Banked", 0)
		st:SetAttribute("Quota", Crews.quota(1, 1, Config.QUOTA_SOLO, Config.QUOTA_PER_EXTRA, Config.QUOTA_GROWTH))
		st:SetAttribute("LampjawCell", 0)
	end
	-- Leaving the server: a crew with nobody left in its level is wiped by
	-- tick(); a crew with nobody left at all just closes.
	Players.PlayerRemoving:Connect(function(player)
		task.defer(function()
			for crew, ctx in active do
				if #CrewService.members(crew) == 0 and not ctx.leaving then
					ctx.leaving = true
					destroy(ctx)
					CrewState.folder(crew):SetAttribute("State", "hub")
				end
			end
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(0.2)
			tick()
			for c = 1, Config.CREW_COUNT do
				hubTick(c, studioSeed[c])
			end
		end
	end)
end

return Sublevels
