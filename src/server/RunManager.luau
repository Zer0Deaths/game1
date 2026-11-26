--!strict
-- RunManager: quotas and the run timer, per crew.
-- Players deposit artefacts at the exit lift; the money goes into their
-- crew's bank. When the timer runs out, every crew that met its quota
-- splits the bank as personal Cash and faces a bigger quota next run.
-- A crew that missed it is wiped: quota back to the start, no pay.
--
-- State is stored as attributes so every client's HUD can read it:
--   Workspace: RunNumber, RunEndsAt (server time), RunState, LiftPosition,
--              Crew<n>Quota, Crew<n>Banked (see CrewService)
--   Player:    Crew, Cash

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Crews = require(Shared:WaitForChild("Crews"))
local ArtefactService = require(script.Parent:WaitForChild("ArtefactService"))
local CrewService = require(script.Parent:WaitForChild("CrewService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local RunManager = {}

local liftPosition: Vector3? = nil
local afterRun: (() -> ())? = nil -- set by main: what happens once a run is over

local function now(): number
	return workspace:GetServerTimeNow()
end

-- Called every time a new level is ready and players are in it.
function RunManager.startRun(lift: Vector3)
	liftPosition = lift
	workspace:SetAttribute("LiftPosition", lift)
	workspace:SetAttribute("RunNumber", (workspace:GetAttribute("RunNumber") or 0) + 1)
	for c = 1, Config.CREW_COUNT do
		workspace:SetAttribute(`Crew{c}Banked`, 0)
	end
	workspace:SetAttribute("RunEndsAt", now() + Config.RUN_SECONDS)
	workspace:SetAttribute("RunState", "playing")
	for _, p in Players:GetPlayers() do
		local crew = p:GetAttribute("Crew") or 1
		Remotes.Notify:FireClient(p, `Run {workspace:GetAttribute("RunNumber")}: {Config.CREW_NAMES[crew]}, deposit ${workspace:GetAttribute(`Crew{crew}Quota`)} at the exit lift`, "banner")
	end
end

-- The Shift moved the lift: update deposits and the compass, keep the run going.
function RunManager.setLift(lift: Vector3)
	liftPosition = lift
	workspace:SetAttribute("LiftPosition", lift)
end

local function insideLift(character: Model): boolean
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local lift = liftPosition
	if not root or not lift then
		return false
	end
	local offset = root.Position - lift
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= Config.LIFT_RADIUS and math.abs(offset.Y) < 8
end

local function checkDeposits()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if character and humanoid and humanoid.Health > 0 and insideLift(character) then
			local total, count = ArtefactService.takeAll(player)
			if count > 0 then
				local crew = player:GetAttribute("Crew") or 1
				local key = `Crew{crew}Banked`
				workspace:SetAttribute(key, (workspace:GetAttribute(key) or 0) + total)
				for _, mate in CrewService.members(crew) do
					Remotes.Notify:FireClient(mate, `{player.DisplayName} deposited {count} item(s): +${total}`, "money")
				end
			end
		end
	end
end

local function endRun()
	workspace:SetAttribute("RunState", "intermission")
	ArtefactService.clearCarried() -- loot still in hands is lost
	local anyMet = false
	for c = 1, Config.CREW_COUNT do
		local members = CrewService.members(c)
		if #members == 0 then
			continue
		end
		local quota = workspace:GetAttribute(`Crew{c}Quota`) or Config.BASE_QUOTA
		local banked = workspace:GetAttribute(`Crew{c}Banked`) or 0
		local met, nextQuota, each = Crews.settle(quota, banked, #members, Config.QUOTA_GROWTH, Config.BASE_QUOTA)
		workspace:SetAttribute(`Crew{c}Quota`, nextQuota)
		anyMet = anyMet or met
		for _, p in members do
			if met then
				p:SetAttribute("Cash", (p:GetAttribute("Cash") or 0) + each)
				Remotes.Notify:FireClient(p, `QUOTA MET  ${banked} / ${quota}. You take home ${each}. Next quota: ${nextQuota}`, "banner")
			else
				Remotes.Notify:FireClient(p, `QUOTA FAILED  ${banked} / ${quota}. {Config.CREW_NAMES[c]} is wiped.`, "banner")
			end
		end
	end
	if not anyMet then
		workspace:SetAttribute("RunNumber", 0)
	end
	task.wait(Config.INTERMISSION_SECONDS)
	if afterRun then
		afterRun()
	end
end

function RunManager.init(onRunOver: () -> ())
	afterRun = onRunOver
	task.spawn(function()
		while true do
			task.wait(0.2)
			if workspace:GetAttribute("RunState") == "playing" then
				checkDeposits()
				if now() >= (workspace:GetAttribute("RunEndsAt") or math.huge) then
					endRun()
				end
			end
		end
	end)
end

return RunManager
