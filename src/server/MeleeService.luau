--!strict
-- MeleeService: swinging the armoury weapons (ShopItems kind "melee").
--
-- The weapon in your hand is the Player attribute Melee (its id) with
-- MeleeUses hits left (ShopService sells it). Click to swing: your device
-- plays the swing and sends where you're looking; the server checks the
-- cooldown and what's in reach:
--   The Tenant   stunned for the weapon's `stun` seconds. The server sets
--                StunnedUntil (server time) and StunFrom (where you stood)
--                on its model; Tenant.luau stops dead, can't take anyone,
--                drops its chase and wakes up dazed, wandering.
--   Lampjaw      hit the red-strobing light it's in and the fitting
--                smashes: it's driven out for a long while.
--   The Foreman  can't be hit: it's closing time, not a body.
-- Every swing is a noise the Tenant can hear (a hit louder still), and
-- inside the Quiet's ring a swing is a sound like any other.
-- A hit costs one use; at 0 the weapon breaks. You lose it if you die.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopItems = require(Shared:WaitForChild("ShopItems"))
local MeleeModels = require(script.Parent:WaitForChild("MeleeModels"))
local NoiseService = require(script.Parent:WaitForChild("NoiseService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))

local MeleeService = {}

local TENANT_RADIUS = 1.6 -- studs: how wide the Tenant's body is around its middle
local ARC = math.cos(math.rad(55)) -- how far off your aim a hit still lands

local byId: { [string]: ShopItems.Item } = {}
for _, item in ShopItems do
	if item.kind == "melee" then
		byId[item.id] = item
	end
end

local lastSwing: { [Player]: number } = {}
local ctxOf: (Player) -> any = function()
	return nil
end

local function now(): number
	return workspace:GetServerTimeNow()
end

-- Put the right weapon in the character's hand (or none).
local function dress(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("Melee")
	local id = player:GetAttribute("Melee")
	if old and old:GetAttribute("Weapon") == id then
		return
	end
	if old then
		old:Destroy()
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if typeof(id) == "string" and byId[id] and hand and hand:IsA("BasePart") then
		MeleeModels.held(id, hand)
	end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Nothing solid between your head and the point you hit.
local function clear(from: Vector3, to: Vector3, ignore: { Instance }): boolean
	local exclude = table.clone(ignore)
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(from, to - from, rayParams)
	return hit == nil or (hit.Position - to).Magnitude < 0.6
end

-- The closest Tenant of this crew in reach and in front of you.
local function tenantInReach(crew: number, eye: Vector3, look: Vector3, reach: number): (Model?, Vector3?)
	local best: Model?, bestPoint: Vector3?, bestDist = nil, nil, math.huge
	for _, inst in CollectionService:GetTagged("SHIFT_Tenant") do
		if not inst:IsA("Model") or inst.Parent ~= workspace or inst:GetAttribute("Crew") ~= crew then
			continue
		end
		local base = inst:GetPivot().Position
		local _, size = inst:GetBoundingBox()
		-- The nearest point on its body's centre line, then out by its girth.
		local y = math.clamp(eye.Y, base.Y + 0.5, base.Y + math.max(size.Y, 2) - 0.5)
		local axis = Vector3.new(base.X, y, base.Z)
		local to = axis - eye
		local flat = Vector3.new(to.X, 0, to.Z)
		local dist = math.max(0, to.Magnitude - TENANT_RADIUS)
		if dist > reach or dist >= bestDist then
			continue
		end
		local lookFlat = Vector3.new(look.X, 0, look.Z)
		local inFront = flat.Magnitude < TENANT_RADIUS
			or (lookFlat.Magnitude > 0.05 and lookFlat.Unit:Dot(flat.Unit) >= ARC)
		if inFront and clear(eye, axis, { inst }) then
			best, bestPoint, bestDist = inst, axis - to.Unit * math.min(TENANT_RADIUS, to.Magnitude), dist
		end
	end
	return best, bestPoint
end

local function swing(player: Player, look: unknown)
	local id = player:GetAttribute("Melee")
	local item = if typeof(id) == "string" then byId[id] else nil
	if not item or typeof(look) ~= "Vector3" or look.Magnitude < 0.5 or look.Magnitude > 1.5 then
		return
	end
	local spec = item.melee :: ShopItems.Melee
	local t = now()
	if t - (lastSwing[player] or 0) < spec.cooldown * 0.9 then
		return -- a little slack for lag
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not humanoid or humanoid.Health <= 0 or not head then
		return
	end
	lastSwing[player] = t
	local dir = (look :: Vector3).Unit
	local eye = head.Position
	Remotes.Fx:FireAllClients("melee_swing", eye + dir * 2)
	local ctx = ctxOf(player)
	if not ctx then
		return -- the safehouse: practice swings
	end
	NoiseService.emit(eye, spec.noise, player)

	local hitAt: Vector3? = nil
	local what = ""
	local tenant, point = tenantInReach(ctx.crew, eye, dir, spec.reach)
	if tenant and point then
		tenant:SetAttribute("StunnedUntil", math.max((tenant:GetAttribute("StunnedUntil") or 0) :: number, t + spec.stun))
		tenant:SetAttribute("StunFrom", eye)
		hitAt, what = point, "tenant"
		print(`[Melee] {player.Name} stunned the Tenant ({item.name}, {spec.stun} s)`)
	elseif ctx.lampjaw and ctx.lampjaw.strike(eye, dir, spec.reach, player) then
		hitAt, what = eye + dir * 3, "light"
	end
	if not hitAt then
		return
	end
	NoiseService.emit(hitAt, spec.noise * 1.5, player)
	Remotes.Fx:FireAllClients(if what == "light" then "melee_glass" else "melee_hit", hitAt)
	local left = ((player:GetAttribute("MeleeUses") or spec.uses) :: number) - 1
	if left <= 0 then
		ShopService.clearMelee(player)
		Remotes.Notify:FireClient(player, `Your {item.name} broke.`, "warn")
	else
		player:SetAttribute("MeleeUses", left)
	end
end

-- Sublevels tells this how to find a player's live level.
function MeleeService.init(levelOf: (Player) -> any)
	ctxOf = levelOf
	Remotes.guard(Remotes.Swing, 4, swing)
	local function onPlayer(player: Player)
		player:GetAttributeChangedSignal("Melee"):Connect(function()
			dress(player)
		end)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
			character:WaitForChild("RightHand", 10)
			dress(player)
			if humanoid then
				humanoid.Died:Connect(function()
					ShopService.clearMelee(player) -- it stays down there with you
				end)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
		dress(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastSwing[p] = nil
	end)
end

return MeleeService
