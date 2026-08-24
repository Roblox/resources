--!strict

--[[
	Provides an array of all item IDs in a specified parent, sorted by
	lowest purchase cost first, and alphabetical DisplayName second.

	This is used for items in the game meant to be displayed in a UI,
	such as pots and plants.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local ContainerByCategory = require(ReplicatedStorage.Source.SharedConstants.ContainerByCategory)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)

local function getSortedIdsInCategory(itemCategory: ItemCategory.EnumType)
	local models = ContainerByCategory[itemCategory]:GetChildren()
	local sortedModels: { Instance } = Freeze.List.sort(models, function(itemA: Instance, itemB: Instance)
		-- Coin bundles don't have Display Names or Purchase Costs
		if itemCategory == ItemCategory.CoinBundles then
			local itemAValue: number = getAttribute(itemA, Attribute.CoinBundleSize)
			local itemBValue: number = getAttribute(itemB, Attribute.CoinBundleSize)

			return itemAValue < itemBValue
		else
			local itemAName: number = getAttribute(itemA, Attribute.DisplayName)
			local itemBName: number = getAttribute(itemB, Attribute.DisplayName)

			local itemAValue: number = getAttribute(itemA, Attribute.PurchaseCost)
			local itemBValue: number = getAttribute(itemB, Attribute.PurchaseCost)

			-- Sort by cost first, alphabetical display name second
			if itemAValue == itemBValue then
				return itemAName < itemBName
			else
				return itemAValue < itemBValue
			end
		end
	end)

	-- Convert the array of models to an array of item IDs
	local sortedItemIds: { string } = Freeze.List.map(sortedModels, function(itemModel: Instance)
		return itemModel.Name
	end)

	return sortedItemIds
end

return getSortedIdsInCategory
