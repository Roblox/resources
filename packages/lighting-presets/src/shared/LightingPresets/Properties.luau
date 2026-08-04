--!strict

-- As there is no API to get the properties of an instance, all properties we wish to change have been hardcoded here

local Properties = {
	Lighting = {
		"Ambient",
		"Brightness",
		"ColorShift_Bottom",
		"ColorShift_Top",
		"EnvironmentDiffuseScale",
		"EnvironmentSpecularScale",
		"GlobalShadows",
		"OutdoorAmbient",
		"ShadowSoftness",
		"ClockTime",
		"GeographicLatitude",
		"ExposureCompensation",
	},
	Sky = {
		"CelestialBodiesShown",
		"MoonAngularSize",
		"MoonTextureId",
		"SkyboxBk",
		"SkyboxDn",
		"SkyboxFt",
		"SkyboxLf",
		"SkyboxRt",
		"SkyboxUp",
		"StarCount",
		"SunAngularSize",
		"SunTextureId",
	},
	Atmosphere = {
		"Density",
		"Offset",
		"Color",
		"Decay",
		"Glare",
		"Haze",
	},
	BloomEffect = {
		"Enabled",
		"Intensity",
		"Size",
		"Threshold",
	},
	BlurEffect = {
		"Enabled",
		"Size",
	},
	ColorCorrectionEffect = {
		"Brightness",
		"Contrast",
		"Enabled",
		"Saturation",
		"TintColor",
	},
	DepthOfFieldEffect = {
		"Enabled",
		"FarIntensity",
		"FocusDistance",
		"InFocusRadius",
		"NearIntensity",
	},
	SunRaysEffect = {
		"Enabled",
		"Intensity",
		"Spread",
	},
}

return Properties
