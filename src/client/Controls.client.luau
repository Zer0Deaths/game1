-- Drop the artefact in your hand: G on keyboard, X on gamepad, or the
-- "Drop" button on phones (ContextActionService makes it for us).

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DropArtefact = Remotes:WaitForChild("DropArtefact") :: RemoteEvent

local function onDrop(_, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin then
		DropArtefact:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("DropArtefact", onDrop, true, Enum.KeyCode.G, Enum.KeyCode.ButtonX)
ContextActionService:SetTitle("DropArtefact", "Drop")
ContextActionService:SetPosition("DropArtefact", UDim2.new(1, -160, 1, -150))
