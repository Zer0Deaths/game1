-- Runs on each player's device. Synced to StarterPlayerScripts.Client.main
-- Fluorescent flicker for ceiling panels tagged "FlickerLight".
-- Done on the client so the server never sends light changes over the
-- network. Each light is calm most of the time, then stutters in bursts,
-- like a dying tube.

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
	panel.Color = if level >= 1 then ON elseif level > 0 then DIM else OFF
	local light = panel:FindFirstChildOfClass("SurfaceLight")
	if light then
		light.Enabled = level > 0
		light.Brightness = FULL_BRIGHTNESS * level
	end
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, inst in CollectionService:GetTagged("FlickerLight") do
		if not inst:IsA("BasePart") then
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
				local roll = math.random()
				setLevel(panel, if roll < 0.45 then 0 elseif roll < 0.7 then 0.5 else 1)
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
