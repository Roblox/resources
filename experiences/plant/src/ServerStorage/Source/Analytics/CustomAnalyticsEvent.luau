--!strict

--[[
	Enums used by CustomAnalytics for tracking game events via analytics dashboard on CreatorHub
--]]

export type EnumType = "HarvestSold" | "SeedPlanted" | "PlantWatered" | "PlantHarvested"

local CustomAnalyticsEvent = {
	HarvestSold = "HarvestSold" :: "HarvestSold",
	SeedPlanted = "SeedPlanted" :: "SeedPlanted",
	PlantWatered = "PlantWatered" :: "PlantWatered",
	PlantHarvested = "PlantHarvested" :: "PlantHarvested",
}

return CustomAnalyticsEvent
