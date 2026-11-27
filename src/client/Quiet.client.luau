--!strict
-- The Quiet on this device (the server side is Quiet.luau). When the hum
-- dies in a ring of cells (Workspace QuietState / QuietCell / QuietRadius,
-- mirrored from your crew by CrewMirror):
--   falling  if you're in the ring the hum sags in pitch and drains away,
--            and the heartbeat goes with it (halfway if you're one cell
--            outside the ring)
--   silent   dead silence, then one slow inhale just behind you
--   idle     the hum comes back
-- The tubes in the ring dim (main.client), so you can see a ring from
-- outside it. Your own footsteps are left alone on purpose: in the silence
-- they're the loudest thing there is.
-- The inhale is QUIET_INHALE; until it's uploaded, whispers slowed right
-- down stand in for it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local player = Players.LocalPlayer
local CELL = 20 -- studs per cell (LevelBuilder.CELL)
local Q = Config.QUIET
local DUCKED = { "Ambience", "Tension" } -- the hum, drone, whispers and heartbeat; entities stay audible

-- How deep in the silence this device is: 1 in the ring, 0.5 one cell
-- outside it, 0 anywhere else (or when there's no ring).
local function depthHere(): number
	local st = workspace:GetAttribute("QuietState")
	local key = (workspace:GetAttribute("QuietCell") or 0) :: number
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local origin = workspace:GetAttribute("LevelOrigin")
	if (st ~= "falling" and st ~= "silent") or key == 0 or not root or typeof(origin) ~= "Vector3" then
		return 0
	end
	local p = root.Position - origin
	local x, z = math.floor(p.X / CELL) + 1, math.floor(p.Z / CELL) + 1
	local radius = (workspace:GetAttribute("QuietRadius") or Q.radiusCells) :: number
	local far = math.max(math.abs(x - key // 1000), math.abs(z - key % 1000))
	return if far <= radius then 1 elseif far == radius + 1 then 0.5 else 0
end

local function shiftOn(): boolean
	return workspace:GetAttribute("ShiftWarning") == true or workspace:GetAttribute("Shifting") == true
end

local humTween: Tween? = nil
local function sagHum(speed: number, seconds: number)
	local hum = SoundService:FindFirstChild("FluorescentHum")
	if not (hum and hum:IsA("Sound")) then
		return
	end
	if humTween then
		humTween:Cancel()
	end
	humTween = TweenService:Create(hum, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { PlaybackSpeed = speed })
	;(humTween :: Tween):Play()
end

local inhale: Sound? = nil
local function breathe()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	-- Close behind you and a little to one side: you won't see anything.
	local cf = root.CFrame
	local side = if math.random() < 0.5 then -1 else 1
	local at = cf.Position - cf.LookVector * 3.5 + cf.RightVector * side * 1.5 + Vector3.new(0, 1.2, 0)
	local real = Audio.id("QUIET_INHALE") ~= nil
	inhale = Audio.at("QUIET_INHALE", at, {
		fallback = "WHISPERS",
		group = "Stingers", -- not ducked with the rest
		volume = if real then 0.8 else 0.55,
		speed = if real then 1 else 0.45,
		minDistance = 4,
		maxDistance = 30,
	})
	local s = inhale
	if s and not real then
		-- The stand-in is a long bed: take one breath of it and fade.
		task.delay(1.4, function()
			if s.Parent then
				TweenService:Create(s, TweenInfo.new(0.5), { Volume = 0 }):Play()
			end
		end)
		task.delay(2, function()
			s:Destroy()
		end)
	end
end

local level = 0 -- how ducked we are now
local phase = "idle"
local breathed = false

local function apply(target: number, seconds: number)
	if target == level then
		return
	end
	level = target
	if shiftOn() then
		return -- the Shift owns the sound (Ambience.client)
	end
	for _, name in DUCKED do
		Audio.fadeGroup(name, 1 - target, seconds)
	end
	sagHum(1 - 0.3 * target, seconds)
end

RunService.Heartbeat:Connect(function()
	local st = (workspace:GetAttribute("QuietState") or "idle") :: string
	local here = depthHere()
	if st ~= phase then
		local was = phase
		phase = st
		if st == "idle" then
			breathed = false
			if inhale and inhale.Parent then
				inhale:Destroy()
			end
			if level > 0 then
				-- The hum comes back quick, like power returning. If a Shift
				-- cut the Quiet short, its warning owns the hum's pitch, and
				-- its blackout owns the silence.
				if workspace:GetAttribute("Shifting") ~= true then
					for _, name in DUCKED do
						Audio.fadeGroup(name, 1, 0.5)
					end
				end
				if not shiftOn() then
					sagHum(1, 0.35)
				end
			end
			level = 0
			return
		elseif st == "silent" and was ~= "silent" and here >= 1 and not breathed then
			breathed = true
			task.delay(0.6 + math.random() * 0.8, function()
				if phase == "silent" and depthHere() >= 1 then
					breathe()
				end
			end)
		end
	end
	if st == "idle" then
		return
	end
	-- Walking into a ring (or out of one) fades you in (or out) of the silence.
	apply(here, if st == "falling" then Q.warnSeconds else 0.4)
end)

