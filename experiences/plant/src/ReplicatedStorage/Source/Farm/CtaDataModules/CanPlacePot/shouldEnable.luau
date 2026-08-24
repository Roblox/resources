--!strict

--[[
	Defines ProximityPrompt visibility logic specific to the CanPlacePot cta
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

local countInventoryItemsInCategory = require(ReplicatedStorage.Source.Utility.PlayerData.countInventoryItemsInCategory)

local function shouldEnable(promptParent: Instance)
	if UIHandler.areMenusVisible() then
		return false
	end

	-- Only show when player has a pot to place
	local numPotsOwned = countInventoryItemsInCategory(ItemCategory.Pots)
	return numPotsOwned > 0
end

return shouldEnable
