--[[
	CollectionService tags indicating state of pots,
	used by CallToAction logic to determine UI visibility
--]]

export type EnumType = "CanPlant" | "CanRemove"

local PotTag = {
	CanPlant = "CanPlant" :: "CanPlant",
	CanRemove = "CanRemove" :: "CanRemove",
}

return PotTag
