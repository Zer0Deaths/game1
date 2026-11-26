-- Runs on each player's device. Synced to StarterPlayerScripts.Client.main
-- Makes ceiling panels tagged "FlickerLight" flicker. Done on the client
-- so the server doesn't send light changes over the network every frame.

local CollectionService = game:GetService("CollectionService")

local ON = Color3.fromRGB(255, 244, 214)
local OFF = Color3.fromRGB(70, 68, 60)

local function setLit(panel: BasePart, lit: boolean)
	panel.Material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
	panel.Color = if lit then ON else OFF
	local light = panel:FindFirstChildOfClass("SurfaceLight")
	if light then
		light.Enabled = lit
	end
end

while true do
	for _, panel in CollectionService:GetTagged("FlickerLight") do
		if panel:IsA("BasePart") then
			-- Mostly on, with short random drop-outs.
			setLit(panel, math.random() > 0.15)
		end
	end
	task.wait(0.05 + math.random() * 0.25)
end
