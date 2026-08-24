--!strict

--[[
	Returns a category from ItemCategory corresponding with
	a given itemId. ItemCategory must contain a string matching the name
	of the folder that the item is in, and itemIds must be unique across all categories.
--]]

-- TODO: Transition all scripts to using this method instead of passing ItemCategory through parameters
-- TODO: Cache this

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local instancesFolder: Folder = getInstance(ReplicatedStorage, "Instances")

local function getCategoryForItemId(itemId: string): ItemCategory.EnumType
	local itemModel: Instance? = instancesFolder:FindFirstChild(itemId, true)
	assert(itemModel, string.format("No item exists for %s", itemId))

	local instanceName = (itemModel.Parent :: Instance).Name
	assert(ItemCategory[instanceName], "ItemId %s has parent named %s, which is not a valid ItemCategory")
	local itemCategory: ItemCategory.EnumType = instanceName :: ItemCategory.EnumType

	return itemCategory
end

return getCategoryForItemId
