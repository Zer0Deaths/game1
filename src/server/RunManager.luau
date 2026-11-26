--!strict
-- RunManager: the quota and the run timer.
-- Players deposit artefacts at the exit lift; the money goes into one
-- shared total for the whole server. Beat the quota before time runs out
-- and the next run asks for more. Miss it and the quota resets.
--
-- State is stored as Workspace attributes so every client's HUD can read it:
--   RunNumber, RunQuota, RunBanked, RunEndsAt (server time), RunState,
--   LiftPosition (Vector3, used by the compass)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ArtefactService = require(script.Parent:WaitForChild("ArtefactService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local RunManager = {}

local liftPosition: Vector3? = nil
local nextLevel: (() -> ())? = nil -- set by main: builds a fresh level then calls startRun

local function now(): number
	return workspace:GetServerTimeNow()
end

-- Called every time a new level is ready.
function RunManager.startRun(lift: Vector3)
	liftPosition = lift
	workspace:SetAttribute("LiftPosition", lift)
	workspace:SetAttribute("RunNumber", (workspace:GetAttribute("RunNumber") or 0) + 1)
	workspace:SetAttribute("RunQuota", workspace:GetAttribute("RunQuota") or Config.BASE_QUOTA)
	workspace:SetAttribute("RunBanked", 0)
	workspace:SetAttribute("RunEndsAt", now() + Config.RUN_SECONDS)
	workspace:SetAttribute("RunState", "playing")
	Remotes.Notify:FireAllClients(
		`Run {workspace:GetAttribute("RunNumber")}: deposit ${workspace:GetAttribute("RunQuota")} at the exit lift`,
		"banner"
	)
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
				local banked = (workspace:GetAttribute("RunBanked") or 0) + total
				workspace:SetAttribute("RunBanked", banked)
				Remotes.Notify:FireAllClients(`{player.DisplayName} deposited {count} item(s): +${total}`, "money")
			end
		end
	end
end

local function endRun()
	workspace:SetAttribute("RunState", "intermission")
	local quota = workspace:GetAttribute("RunQuota") or Config.BASE_QUOTA
	local banked = workspace:GetAttribute("RunBanked") or 0
	ArtefactService.clearCarried() -- loot still in hands is lost
	if banked >= quota then
		local nextQuota = math.floor(quota * Config.QUOTA_GROWTH / 10 + 0.5) * 10
		Remotes.Notify:FireAllClients(`QUOTA MET  ${banked} / ${quota}. Next quota: ${nextQuota}`, "banner")
		workspace:SetAttribute("RunQuota", nextQuota)
	else
		Remotes.Notify:FireAllClients(`QUOTA FAILED  ${banked} / ${quota}. The lobby is wiped.`, "banner")
		workspace:SetAttribute("RunQuota", Config.BASE_QUOTA)
		workspace:SetAttribute("RunNumber", 0)
	end
	task.wait(Config.INTERMISSION_SECONDS)
	if nextLevel then
		nextLevel()
	end
end

function RunManager.init(buildNextLevel: () -> ())
	nextLevel = buildNextLevel
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
