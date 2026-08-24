--!strict

--[[
	Returns the Seed Id associated with a given Plant Id
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContainerByCategory = require(ReplicatedStorage.Source.SharedConstants.ContainerByCategory)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)

local function getSeedIdFromPlantId(plantId: string)
	for _, seedModel in ipairs(ContainerByCategory[ItemCategory.Seeds]:GetChildren()) do
		if getAttribute(seedModel, Attribute.PlantId) == plantId then
			return seedModel.Name
		end
	end

	error("No SeedId found with a matching PlantId attribute for " .. plantId)
end

return getSeedIdFromPlantId
