--!strict
-- Atmosphere: lighting, haze, colour grading and reverb for The Carpet.
-- Everything here replicates to players automatically (it lives in
-- Lighting and SoundService), so the server sets it once.
--
-- Tweak the numbers in LOOK while playtesting; they are first guesses.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Atmosphere = {}

local LOOK = {
	ambient = Config.AMBIENT, -- light in places no lamp reaches (shared with StartupLight)
	exposure = 0.25, -- overall brightness boost

	hazeColor = Color3.fromRGB(150, 128, 70), -- the yellow murk far away
	hazeDecay = Color3.fromRGB(60, 46, 18),
	hazeDensity = 0.42, -- higher = corridors vanish sooner
	haze = 2.2,

	tint = Color3.fromRGB(255, 240, 200), -- sickly warm tint
	saturation = -0.25, -- washed-out, old-photo colours
	contrast = 0.12,

	bloomIntensity = 0.7, -- glow around the neon light panels
	bloomSize = 28,
	bloomThreshold = 0.92,
}

local function getOrMake(className: string, name: string, parent: Instance): any
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	local inst = Instance.new(className :: any) :: Instance
	inst.Name = name
	inst.Parent = parent
	return inst
end

function Atmosphere.apply()
	-- Night, no sun, no sky light: only the ceiling panels light the level.
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.Ambient = LOOK.ambient
	Lighting.OutdoorAmbient = LOOK.ambient
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.ExposureCompensation = LOOK.exposure
	Lighting.GlobalShadows = true

	-- Atmosphere replaces the old Fog settings and gives a softer, thicker haze.
	local atmo = getOrMake("Atmosphere", "LiminalHaze", Lighting) :: Atmosphere
	atmo.Color = LOOK.hazeColor
	atmo.Decay = LOOK.hazeDecay
	atmo.Density = LOOK.hazeDensity
	atmo.Offset = 0
	atmo.Glare = 0
	atmo.Haze = LOOK.haze

	local grade = getOrMake("ColorCorrectionEffect", "LiminalGrade", Lighting) :: ColorCorrectionEffect
	grade.TintColor = LOOK.tint
	grade.Saturation = LOOK.saturation
	grade.Contrast = LOOK.contrast
	grade.Brightness = 0

	local bloom = getOrMake("BloomEffect", "LiminalBloom", Lighting) :: BloomEffect
	bloom.Intensity = LOOK.bloomIntensity
	bloom.Size = LOOK.bloomSize
	bloom.Threshold = LOOK.bloomThreshold

	-- A Sky from the default place would show through nothing (we have a
	-- ceiling), but its ambient light still leaks in. Remove it at runtime.
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end

	-- Footsteps and voices echo like an empty office corridor.
	SoundService.AmbientReverb = Enum.ReverbType.Hallway
end

-- Per-level-type haze and colour grade (see LevelTypes.luau).
function Atmosphere.applyTheme(haze: { colour: Color3, decay: Color3, density: number }, tint: Color3)
	local atmo = Lighting:FindFirstChild("LiminalHaze") :: Atmosphere?
	if atmo then
		atmo.Color = haze.colour
		atmo.Decay = haze.decay
		atmo.Density = haze.density
	end
	local grade = Lighting:FindFirstChild("LiminalGrade") :: ColorCorrectionEffect?
	if grade then
		grade.TintColor = tint
	end
end

return Atmosphere
