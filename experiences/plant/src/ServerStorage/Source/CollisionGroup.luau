--!strict

--[[
	Pseudo enums used to give unique names to CollisionGroups that
	get created at runtime.

	These provide a way to reference the groups by name in scripts,
	which avoids referencing them with typo-prone strings
--]]

export type EnumType = "Character" | "Wagon"

local CollisionGroup = {
	Character = "Character" :: "Character",
	Wagon = "Wagon" :: "Wagon",
}

return CollisionGroup
