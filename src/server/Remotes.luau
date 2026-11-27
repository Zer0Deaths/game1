-- Creates the RemoteEvents clients and server talk through.
-- They live in ReplicatedStorage.Remotes (made at runtime, not by Rojo).
--   DropArtefact  client -> server  "drop what I'm holding"
--   Notify        server -> client  (text, kind) for toasts and banners
--   MapSync       server -> client  ("reset", width, depth) or ("cells", {entries}) for the shared map
--   MapRequest    client -> server  "send me the whole map" (on join)
--   OpenShop      server -> client  open the shop screen (safehouse counter)
--   BuyItem       client -> server  (itemId) buy something in the shop
--   ToggleFlashlight client -> server  switch your flashlight on/off
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

return {
	DropArtefact = event("DropArtefact"),
	Notify = event("Notify"),
	MapSync = event("MapSync"),
	MapRequest = event("MapRequest"),
	OpenShop = event("OpenShop"),
	BuyItem = event("BuyItem"),
	ToggleFlashlight = event("ToggleFlashlight"),
	Fx = event("Fx"),
}
