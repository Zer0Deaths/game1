-- Creates the RemoteEvents clients and server talk through.
-- They live in ReplicatedStorage.Remotes (made at runtime, not by Rojo).
--   DropArtefact  client -> server  "drop what I'm holding"
--   Notify        server -> client  (text, kind) for toasts and banners
--   MapSync       server -> client  ("reset", width, depth) or ("cells", {entries}) for the shared map
--   MapRequest    client -> server  "send me the whole map" (on join)
--   OpenShop      server -> client  open the shop screen (safehouse counter)
--   BuyItem       client -> server  (itemId) buy something in the shop
--   ToggleFlashlight client -> server  switch your flashlight on/off
--   Swing         client -> server  (lookVector) swing the melee weapon in your hand
--   OpenShop also carries "lift" for the armoury in the exit lift
--   Fx            server -> client  (kind, position) one-off sounds and effects: pickup, drop, death

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
folder.Name = "Remotes"
folder.Parent = ReplicatedStorage

local function event(name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing :: RemoteEvent
	end
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = folder
	return e
end

-- Every client -> server remote goes through guard(): it drops calls from
-- players spamming it (more than `perSecond` a second, with a small burst
-- allowance) and never lets a handler error take the remote down. Each
-- handler still checks its own arguments and the player's state.
local buckets: { [RemoteEvent]: { [Player]: { tokens: number, at: number } } } = {}
local function guard(remote: RemoteEvent, perSecond: number, handler: (Player, ...any) -> ()): RBXScriptConnection
	buckets[remote] = buckets[remote] or {}
	local b = buckets[remote]
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		b[p] = nil
	end)
	return remote.OnServerEvent:Connect(function(player: Player, ...)
		local now = os.clock()
		local entry = b[player]
		if not entry then
			entry = { tokens = perSecond * 2, at = now }
			b[player] = entry
		end
		entry.tokens = math.min(perSecond * 2, entry.tokens + (now - entry.at) * perSecond)
		entry.at = now
		if entry.tokens < 1 then
			return -- too fast: ignore
		end
		entry.tokens -= 1
		local ok, err = pcall(handler, player, ...)
		if not ok then
			warn(`[Remotes] {remote.Name} from {player.Name} failed: {err}`)
		end
	end)
end

return {
	guard = guard,
	DropArtefact = event("DropArtefact"),
	Notify = event("Notify"),
	MapSync = event("MapSync"),
	MapRequest = event("MapRequest"),
	OpenShop = event("OpenShop"),
	BuyItem = event("BuyItem"),
	ToggleFlashlight = event("ToggleFlashlight"),
	Fx = event("Fx"),
	Swing = event("Swing"),
}
