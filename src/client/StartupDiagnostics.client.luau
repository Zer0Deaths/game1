-- Temporary: prints what the lighting looks like on this device for the
-- first 20 seconds after joining, once per second, so we can see why the
-- start might be dark. Look for "[Diag]" lines in Output (Client view).
-- Safe to delete once the start-up darkness is confirmed fixed.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local started = os.clock()
local okTech, tech = pcall(function()
	return Lighting.Technology.Name
end)
print(`[Diag] StreamingEnabled={workspace.StreamingEnabled} Technology={if okTech then tech else "unreadable"}`)

for _ = 1, 20 do
	local panels, lit = 0, 0
	for _, panel in CollectionService:GetTagged("CeilingLight") do
		panels += 1
		local light = panel:FindFirstChildOfClass("SurfaceLight")
		if light and light.Enabled and light.Brightness > 0 then
			lit += 1
		end
	end
	local level = workspace:FindFirstChild("Level")
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local grade = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	print(
		string.format(
			"[Diag] t=%.0fs level=%s parts=%d lights=%d lit=%d shifting=%s warning=%s char=%s pos=%s exposure=%.2f grade=%s",
			os.clock() - started,
			tostring(level ~= nil),
			level and #level:GetDescendants() or 0,
			panels,
			lit,
			tostring(workspace:GetAttribute("Shifting")),
			tostring(workspace:GetAttribute("ShiftWarning")),
			tostring(root ~= nil),
			if root then string.format("%.0f,%.0f,%.0f", root.Position.X, root.Position.Y, root.Position.Z) else "-",
			Lighting.ExposureCompensation,
			if grade then string.format("%.2f", grade.Brightness) else "none"
		)
	)
	task.wait(1)
end
