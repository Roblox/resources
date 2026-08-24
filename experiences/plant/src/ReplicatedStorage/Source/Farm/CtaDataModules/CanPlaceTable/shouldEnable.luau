--!strict

--[[
	Defines ProximityPrompt visibility logic specific to the CanPlaceTable cta
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

local countInventoryItemsInCategory = require(ReplicatedStorage.Source.Utility.PlayerData.countInventoryItemsInCategory)

local function shouldEnable(promptParent: Instance)
	if UIHandler.areMenusVisible() then
		return false
	end

	-- Only show when player has a table to place
	local numTablesOwned = countInventoryItemsInCategory(ItemCategory.Tables)
	return numTablesOwned > 0
end

return shouldEnable
