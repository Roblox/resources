--!strict

--[[
	Provides functions to track core game loop via custom events for analytics purposes.
	This populates charts that show up in Creator Hub's analytics pages.
	
	Examples of events that can be tracked here include:
	* Player sold their harvest
	* Player planted a seed
	* Player watered a plant
	* Player harvested a plant
--]]

local AnalyticsService = game:GetService("AnalyticsService")

local CustomAnalyticsEvent = require(script.Parent.CustomAnalyticsEvent)

local CustomAnalytics = {}
function CustomAnalytics.logHarvestSold(player: Player, numSoldPlants: number)
	task.spawn(function()
		AnalyticsService:LogCustomEvent(player, CustomAnalyticsEvent.HarvestSold, numSoldPlants)
	end)
end

function CustomAnalytics.logSeedPlanted(player: Player, potId: string, seedId: string)
	task.spawn(function()
		AnalyticsService:LogCustomEvent(player, CustomAnalyticsEvent.SeedPlanted, 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = potId,
			[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = seedId,
		})
	end)
end

function CustomAnalytics.logPlantWatered(player: Player, plantId: string)
	task.spawn(function()
		AnalyticsService:LogCustomEvent(player, CustomAnalyticsEvent.PlantWatered, 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = plantId,
		})
	end)
end

function CustomAnalytics.logPlantHarvested(player: Player, plantId: string)
	task.spawn(function()
		AnalyticsService:LogCustomEvent(player, CustomAnalyticsEvent.PlantHarvested, 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = plantId,
		})
	end)
end

return CustomAnalytics
