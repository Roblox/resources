--!strict

--[[
	A source of truth list of all attributes used by scripts. Allows
	scripts to reference attributes by name without typo-prone strings
	that won't be caught until runtime.
--]]

export type EnumType =
	"FeaturePackagesStart"
	| "FeaturePackagesEnd"
	| "FeaturePackagesIncludeSuffix"
	| "FeaturePackagesMaxUnits"
	| "FeaturePackagesTimerExpired"
local Attributes = {
	FeaturePackagesStart = "FeaturePackagesStart" :: "FeaturePackagesStart",
	FeaturePackagesEnd = "FeaturePackagesEnd" :: "FeaturePackagesEnd",
	FeaturePackagesIncludeSuffix = "FeaturePackagesIncludeSuffix" :: "FeaturePackagesIncludeSuffix",
	FeaturePackagesMaxUnits = "FeaturePackagesMaxUnits" :: "FeaturePackagesMaxUnits",
	FeaturePackagesTimerExpired = "FeaturePackagesTimerExpired" :: "FeaturePackagesTimerExpired",
}

return Attributes
