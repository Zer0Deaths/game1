--!strict
-- Atmosphere: lighting, haze, colour grading and reverb. Mono-yellow and
-- restrained: dim ambient, a short yellow haze so corridors dissolve into
-- murk a few cells ahead, subtle bloom on the tubes, a warm desaturated
-- grade, and a light depth-of-field softening in the distance.
-- Works with any Lighting.Technology (Jason's is locked), no Future needed.
-- Everything here replicates to players automatically, so the server sets
-- it once. Each level type swaps the haze and tint (CrewMirror.client).
-- Sanity.client darkens and desaturates the grade on your own screen.

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
	hazeDensity = 0.46, -- higher = corridors vanish sooner (0.46: about four cells)
	haze = 2.6,

	tint = Color3.fromRGB(255, 240, 200), -- sickly warm tint
	saturation = -0.22, -- washed-out, old-photo colours
	contrast = 0.1,
	brightness = -0.02,

	bloomIntensity = 0.45, -- a soft glow round the tubes, no more
	bloomSize = 24,
	bloomThreshold = 0.95,

	-- Light depth of field: the far end of a corridor goes soft.
	dofFar = 0.2,
	dofFocus = 22,
	dofRadius = 30,

	-- Metals and glazed tile catch a little reflected light.
	specular = 0.35,
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
	Lighting.EnvironmentSpecularScale = LOOK.specular
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
	grade.Brightness = LOOK.brightness

	local bloom = getOrMake("BloomEffect", "LiminalBloom", Lighting) :: BloomEffect
	bloom.Intensity = LOOK.bloomIntensity
	bloom.Size = LOOK.bloomSize
	bloom.Threshold = LOOK.bloomThreshold

	local dof = getOrMake("DepthOfFieldEffect", "LiminalFocus", Lighting) :: DepthOfFieldEffect
	dof.FarIntensity = LOOK.dofFar
	dof.NearIntensity = 0
	dof.FocusDistance = LOOK.dofFocus
	dof.InFocusRadius = LOOK.dofRadius

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
