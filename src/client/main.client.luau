-- Runs on each player's device. Synced to StarterPlayerScripts.Client.main
-- Ceiling lights, done locally so the server never sends light changes:
--   normal:   panels tagged "FlickerLight" stutter in bursts like dying tubes
--   warning:  (Workspace.ShiftWarning) every light stutters, the Shift is coming
--   blackout: (Workspace.Shifting) every light is off while the maze rewires
--   Lampjaw:  (Workspace.LampjawCell) the light it is hiding in strobes red and buzzes

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local ON = Color3.fromRGB(246, 242, 212)
local DIM = Color3.fromRGB(150, 146, 120)
local OFF = Color3.fromRGB(64, 62, 56)
local FULL_BRIGHTNESS = 2

type FlickerState = {
	nextBurst: number, -- when the next stutter starts
	burstEnd: number, -- when the current stutter ends
	nextToggle: number, -- when to change state inside a stutter
}

local states: { [BasePart]: FlickerState } = {}

local function setLevel(panel: BasePart, level: number)
	-- level: 0 = off, 0.5 = dim, 1 = full
	panel.Material = if level > 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	local on = (workspace:GetAttribute("LightColour") or ON) :: Color3 -- level types tint the lights
	panel.Color = if level >= 1 then on elseif level > 0 then DIM else OFF
	local light = panel:FindFirstChildOfClass("SurfaceLight")
	if light then
		light.Enabled = level > 0
		light.Brightness = FULL_BRIGHTNESS * level
		light.Color = on
	end
end

local function randomLevel(offChance: number): number
	local roll = math.random()
	return if roll < offChance then 0 elseif roll < offChance + 0.25 then 0.5 else 1
end

local function eachCeilingLight(fn: (BasePart) -> ())
	for _, inst in CollectionService:GetTagged("CeilingLight") do
		if inst:IsA("BasePart") then
			fn(inst)
		end
	end
end

local mode = "normal"
local nextStorm = 0

-- Lampjaw's light: a red strobe and an electrical buzz.
local RED_ON = Color3.fromRGB(255, 120, 90)
local RED_DIM = Color3.fromRGB(140, 50, 40)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundIds"))
local lampjawPanel: BasePart? = nil
local lampjawKey = 0
local nextStrobe = 0
local buzz = Instance.new("Sound")
buzz.Name = "LampjawBuzz"
buzz.Looped = true
buzz.Volume = 0.9
buzz.PlaybackSpeed = 2.4
buzz.RollOffMode = Enum.RollOffMode.InverseTapered
buzz.RollOffMinDistance = 6
buzz.RollOffMaxDistance = 60

local function findLampjawPanel(key: number): BasePart?
	if key == 0 then
		return nil
	end
	for _, inst in CollectionService:GetTagged("FlickerLight") do
		if inst:IsA("BasePart") and inst:GetAttribute("Cell") == key then
			return inst
		end
	end
	return nil
end

local function updateLampjaw(now: number, strobe: boolean)
	local key = (workspace:GetAttribute("LampjawCell") or 0) :: number
	if key ~= lampjawKey or (lampjawPanel and not lampjawPanel.Parent) then
		if lampjawPanel and lampjawPanel.Parent then
			setLevel(lampjawPanel, 1)
		end
		lampjawKey = key
		lampjawPanel = findLampjawPanel(key)
		buzz:Stop()
		buzz.Parent = lampjawPanel
		if lampjawPanel then
			local id = SoundIds.get("HUM")
			if id then
				buzz.SoundId = id
				buzz:Play()
			end
		end
	end
	local panel = lampjawPanel
	if panel and strobe and now >= nextStrobe then
		nextStrobe = now + 0.04 + math.random() * 0.09
		local on = math.random() < 0.55
		panel.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		panel.Color = if on then RED_ON else RED_DIM
		local light = panel:FindFirstChildOfClass("SurfaceLight")
		if light then
			light.Enabled = on
			light.Color = RED_ON
			light.Brightness = if on then 1.6 else 0
		end
	end
end

-- Every fitting follows its LightState: dead ones stay dark, working ones
-- come on (unless the Shift has everything blacked out). The server never
-- touches the look after the first build, so this device owns it.
local function syncFitting(inst: Instance)
	if not inst:IsA("BasePart") then
		return
	end
	local dead = inst:GetAttribute("LightState") == "dead"
	setLevel(inst, if dead or mode == "blackout" then 0 else 1)
end
local function watchFitting(inst: Instance)
	syncFitting(inst)
	inst:GetAttributeChangedSignal("LightState"):Connect(function()
		syncFitting(inst)
	end)
end
CollectionService:GetInstanceAddedSignal("LightFitting"):Connect(watchFitting)
for _, inst in CollectionService:GetTagged("LightFitting") do
	watchFitting(inst)
end
-- Lights that start working during a blackout must start dark too.
CollectionService:GetInstanceAddedSignal("CeilingLight"):Connect(function(inst)
	if inst:IsA("BasePart") then
		setLevel(inst, if mode == "blackout" then 0 else 1)
	end
end)

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local wanted = if workspace:GetAttribute("Shifting")
		then "blackout"
		elseif workspace:GetAttribute("ShiftWarning") then "warning"
		else "normal"

	if wanted ~= mode then
		mode = wanted
		if mode == "blackout" then
			eachCeilingLight(function(panel)
				setLevel(panel, 0)
			end)
		elseif mode == "normal" then
			eachCeilingLight(function(panel)
				setLevel(panel, 1)
			end)
			table.clear(states)
		end
	end

	if mode ~= "normal" then
		updateLampjaw(now, false) -- keep its buzz in step, but the Shift owns the lights
	end
	if mode == "blackout" then
		return
	elseif mode == "warning" then
		-- Everything stutters, a few times a second.
		if now >= nextStorm then
			nextStorm = now + 0.06 + math.random() * 0.1
			eachCeilingLight(function(panel)
				if math.random() < 0.35 then
					setLevel(panel, randomLevel(0.4))
				end
			end)
		end
		return
	end

	-- Normal: only the dying tubes stutter, and Lampjaw's light strobes red.
	updateLampjaw(now, true)
	for _, inst in CollectionService:GetTagged("FlickerLight") do
		if not inst:IsA("BasePart") or inst == lampjawPanel then
			continue
		end
		local panel = inst :: BasePart
		local state = states[panel]
		if not state then
			state = { nextBurst = now + math.random() * 6, burstEnd = 0, nextToggle = 0 }
			states[panel] = state
		end
		if now < state.burstEnd then
			if now >= state.nextToggle then
				setLevel(panel, randomLevel(0.45))
				state.nextToggle = now + 0.03 + math.random() * 0.15
			end
		elseif now >= state.nextBurst then
			state.burstEnd = now + 0.3 + math.random() * 1.4
			state.nextBurst = state.burstEnd + 2 + math.random() * 9
		elseif state.burstEnd > 0 then
			setLevel(panel, 1)
			state.burstEnd = 0
		end
	end
	-- Forget panels that were destroyed when the level rebuilt.
	for panel in states do
		if not panel.Parent then
			states[panel] = nil
		end
	end
end)
