--!strict

--[[
	Returns the price of the given itemId
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getCategoryForItemId = require(ReplicatedStorage.Source.Utility.Farm.getCategoryForItemId)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

local function getPurchaseCost(itemId: string)
	local categoryId: ItemCategory.EnumType = getCategoryForItemId(itemId)
	local itemModel = getItemByIdInCategory(itemId, categoryId)

	return getAttribute(itemModel, Attribute.PurchaseCost)
end

return getPurchaseCost
