--!strict

--[[
	Returns a boolean value of whether a plant fits in a pot based on the
	plant size and the pot size. These sizes are pulled from attributes
	on the plant and pot prefabs.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)

local function checkSeedFitsInPot(seedId: string, potId: string)
	local seedModel = getItemByIdInCategory(seedId, ItemCategory.Seeds)
	local potModel = getItemByIdInCategory(potId, ItemCategory.Pots)

	local plantSize: number = getAttribute(seedModel, Attribute.PlantSize)
	local potSize: number = getAttribute(potModel, Attribute.MaxPlantSize)

	return plantSize <= potSize
end

return checkSeedFitsInPot
