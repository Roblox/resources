--!strict

--[[
	Returns the number of itemIds in the local user's inventory
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local getCategoryForItemId = require(ReplicatedStorage.Source.Utility.Farm.getCategoryForItemId)

local function getItemAmountInInventory(itemId: string): number
	local categoryId = getCategoryForItemId(itemId)

	local inventory = PlayerDataClient.get(PlayerDataKey.Inventory)
	local categoryItemCount = inventory[categoryId] or {}
	local itemCount = categoryItemCount[itemId] or 0

	return itemCount
end

return getItemAmountInInventory
