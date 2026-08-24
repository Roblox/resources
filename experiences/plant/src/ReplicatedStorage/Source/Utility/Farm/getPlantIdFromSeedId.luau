--!strict

--[[
	Returns the Plant Id associated with a given Seed Id
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

local function getPlantIdFromSeedId(seedId: string)
	local seedModel = getItemByIdInCategory(seedId, ItemCategory.Seeds)
	return getAttribute(seedModel, Attribute.PlantId)
end

return getPlantIdFromSeedId
