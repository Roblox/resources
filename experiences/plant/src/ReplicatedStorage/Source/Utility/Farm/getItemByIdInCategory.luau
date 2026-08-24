--!strict

--[[
	Returns the item prefab matching the given itemId and category, and
	errors if it doesn't exist. itemId must match the name of the
	item prefab.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContainerByCategory = require(ReplicatedStorage.Source.SharedConstants.ContainerByCategory)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

-- TODO: Only require itemId. Category can be looked up with getCategoryForItemId now that we assume itemIds are unique across categories
local function getItemByIdInCategory(itemId: string, category: ItemCategory.EnumType)
	local item

	local container = ContainerByCategory[category]
	assert(container, string.format("Attempt to get item with invalid category `%s`", category))

	item = container:FindFirstChild(itemId)
	assert(item, string.format("Attempt to get item in category `%s` with invalid itemId `%s`", category, itemId))

	return item :: Model
end

return getItemByIdInCategory
