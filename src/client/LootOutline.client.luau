--!strict
-- LootOutline: a white outline on the one piece of loot you'd pick up
-- with E right now (the pickup prompt Roblox is showing you: in range and
-- in line of sight). One Highlight, moved to whatever the target is.

local ProximityPromptService = game:GetService("ProximityPromptService")

local highlight = Instance.new("Highlight")
highlight.Name = "LootOutline"
highlight.FillTransparency = 1
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.OutlineTransparency = 0
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Enabled = false
highlight.Parent = workspace.CurrentCamera

local current: ProximityPrompt? = nil

-- The whole tool is outlined: its Blender model (welded under the Handle)
-- once that has loaded, the plain Handle part until then.
local function isLoot(prompt: ProximityPrompt): Tool?
	local handle = prompt.Parent
	local tool = handle and handle.Parent
	if handle and handle:IsA("BasePart") and tool and tool:IsA("Tool") and tool:GetAttribute("Artefact") then
		return tool
	end
	return nil
end

local function clear()
	current = nil
	highlight.Adornee = nil
	highlight.Enabled = false
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	local tool = isLoot(prompt)
	if not tool then
		return
	end
	current = prompt
	-- The Handle is invisible once the model is on it, so outline the model.
	local handle = prompt.Parent :: Instance
	highlight.Adornee = handle:FindFirstChild("Visual") or tool
	highlight.Enabled = true
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if prompt == current then
		clear()
	end
end)

-- Picked up by you or someone else, or the item went away: drop the outline.
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt == current then
		clear()
	end
end)

game:GetService("RunService").Heartbeat:Connect(function()
	local p = current
	if p and (not p.Enabled or not p:IsDescendantOf(workspace)) then
		clear()
	end
end)

-- The camera can be replaced (respawn): keep the Highlight under the live one.
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	highlight.Parent = workspace.CurrentCamera
end)
