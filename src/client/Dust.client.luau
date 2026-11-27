--!strict
-- Dust: tiny motes hanging in the air around you, catching the light.
-- They drift in the world (they are not stuck to the screen), so this is
-- not a camera effect. Only this device sees and pays for them.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local box = Instance.new("Part")
box.Name = "DustVolume"
box.Anchored = true
box.CanCollide = false
box.CanQuery = false
box.CanTouch = false
box.CastShadow = false
box.Transparency = 1
box.Size = Vector3.new(44, 9, 44)
box.Parent = workspace

local motes = Instance.new("ParticleEmitter")
motes.Name = "Motes"
motes.Shape = Enum.ParticleEmitterShape.Box
motes.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
motes.Rate = 55
motes.Lifetime = NumberRange.new(7, 12)
motes.Speed = NumberRange.new(0.05, 0.25)
motes.SpreadAngle = Vector2.new(180, 180)
motes.Acceleration = Vector3.new(0, -0.03, 0)
motes.Drag = 0.6
motes.RotSpeed = NumberRange.new(-30, 30)
motes.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.2, 0.06),
	NumberSequenceKeypoint.new(0.8, 0.05),
	NumberSequenceKeypoint.new(1, 0),
})
motes.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.25, 0.35),
	NumberSequenceKeypoint.new(0.75, 0.45),
	NumberSequenceKeypoint.new(1, 1),
})
motes.Color = ColorSequence.new(Color3.fromRGB(255, 246, 214))
motes.LightEmission = 0.15
motes.LightInfluence = 1 -- bright under a light, invisible in the dark
motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
motes.Parent = box

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		-- Follows you, but only moves in steps so the motes stay put in the
		-- world rather than sliding along with you.
		local p = root.Position
		local snapped = Vector3.new(math.round(p.X / 8) * 8, 5.5, math.round(p.Z / 8) * 8)
		if (box.Position - snapped).Magnitude > 0.1 then
			box.Position = snapped
		end
		motes.Enabled = workspace:GetAttribute("Shifting") ~= true
	end
end)
