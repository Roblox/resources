--[[
	CollectionService tags indicating state of plants,
	used by CallToAction logic and water timer UI to determine UI visibility
--]]

export type EnumType = "NeedsWater" | "Growing" | "CanHarvest"

local PlantTag = {
	NeedsWater = "NeedsWater" :: "NeedsWater",
	Growing = "Growing" :: "Growing",
	CanHarvest = "CanHarvest" :: "CanHarvest",
}

return PlantTag
