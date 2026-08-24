--!strict

--[[
	Returns the a count of all items in the local player's inventory that
	are in a given category
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

local function countInventoryItemsInCategory(itemCategory: ItemCategory.EnumType)
	local inventory = PlayerDataClient.get(PlayerDataKey.Inventory)
	local itemCounts = Freeze.Dictionary.values(inventory[itemCategory] or {})
	local totalItemCount = Freeze.List.reduce(itemCounts, function(a: number, b: number)
		return a + b
	end, 0)

	return totalItemCount
end

return countInventoryItemsInCategory
