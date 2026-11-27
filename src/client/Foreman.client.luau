--!strict
-- The Foreman on this device (the server side is Foreman.luau). While it's
-- switching your crew's level off (Workspace ForemanActive):
--   * the lift dings once: it has clocked on,
--   * every light it switches off clunks like a breaker where it is
--     (panels get Switched = true; Map.client darkens them),
--   * its keys jangle on its belt, its boots land heavy, and every so
--     often it whistles two flat notes that carry the length of a corridor.
-- FOREMAN_KEYS and FOREMAN_WHISTLE are our own synthesis (tools/
-- make_sounds.py) and wait on audio uploads; until then the boots and the
-- breakers (the uploaded relay thunk) carry it.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Audio = require(script.Parent:WaitForChild("Audio"))

local player = Players.LocalPlayer

local function mine(inst: Instance): boolean
	return inst:GetAttribute("Crew") == player:GetAttribute("Crew")
end

local function active(): boolean
	return workspace:GetAttribute("ForemanActive") == true
end

-- BREAKERS ---------------------------------------------------------------------

local lastClunk = 0
local CLUNK_RANGE = 150 -- studs: further than this you don't hear it

local function watchPanel(inst: Instance)
	if not inst:IsA("BasePart") then
		return
	end
	local panel = inst :: BasePart
	panel:GetAttributeChangedSignal("Switched"):Connect(function()
		if panel:GetAttribute("Switched") ~= true or not mine(panel) or not active() then
			return
		end
		local cam = workspace.CurrentCamera
		local now = os.clock()
		if not cam or (cam.CFrame.Position - panel.Position).Magnitude > CLUNK_RANGE or now - lastClunk < 0.09 then
			return
		end
		lastClunk = now
		Audio.at("BLACKOUT", panel.Position, { group = "Sfx", volume = 0.55, speed = 1.3, jitter = 0.08, minDistance = 10, maxDistance = CLUNK_RANGE })
	end)
end
CollectionService:GetInstanceAddedSignal("LightFitting"):Connect(watchPanel)
for _, inst in CollectionService:GetTagged("LightFitting") do
	watchPanel(inst)
end

-- CLOCKING ON --------------------------------------------------------------------

workspace:GetAttributeChangedSignal("ForemanActive"):Connect(function()
	if active() then
		Audio.play("LIFT_DING", { volume = 0.45, speed = 0.92 })
		local lift = workspace:GetAttribute("LiftPosition")
		if typeof(lift) == "Vector3" then
			Audio.at("LIFT_DING", lift, { volume = 1, speed = 0.92, minDistance = 20, maxDistance = 300 })
		end
	end
end)

-- THE BODY: keys, boots, whistle ---------------------------------------------

type Body = { model: Model, keys: Sound?, nextStep: number, nextWhistle: number }
local bodies: { [Model]: Body } = {}

local function track(inst: Instance)
	if inst:IsA("Model") and inst:GetAttribute("Entity") == "Foreman" and not bodies[inst] then
		bodies[inst] = { model = inst, keys = nil, nextStep = 0, nextWhistle = os.clock() + 3 + math.random() * 4 }
	end
end
CollectionService:GetInstanceAddedSignal("SHIFT_Entity"):Connect(track)
for _, inst in CollectionService:GetTagged("SHIFT_Entity") do
	track(inst)
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for model, b in bodies do
		local root = model.PrimaryPart
		local here = model.Parent ~= nil and model:IsDescendantOf(workspace) and mine(model) and active() and root ~= nil
		if not model.Parent then
			if b.keys then
				b.keys:Destroy()
			end
			bodies[model] = nil
			continue
		end
		if not here then
			if b.keys then
				b.keys:Destroy()
				b.keys = nil
			end
			continue
		end
		local r = root :: BasePart
		if not b.keys or not b.keys.Parent then
			b.keys = Audio.loop("FOREMAN_KEYS", r, { group = "Entities", volume = 0.8, minDistance = 8, maxDistance = 90 })
		end
		Audio.refresh(b.keys :: Sound)
		local walking = model:GetAttribute("Gait") == "walk"
		;(b.keys :: Sound).Volume = if walking then 0.8 else 0.25
		if walking and now >= b.nextStep then
			b.nextStep = now + 0.58
			Audio.play("STEP_METAL", { group = "Entities", variants = true, volume = 1.3, speed = 0.62, jitter = 0.05, minDistance = 10, maxDistance = 110 }, r)
		end
		if now >= b.nextWhistle then
			b.nextWhistle = now + 9 + math.random() * 7
			Audio.play("FOREMAN_WHISTLE", { group = "Entities", volume = 0.9, jitter = 0.03, minDistance = 25, maxDistance = 260 }, r)
		end
	end
end)
