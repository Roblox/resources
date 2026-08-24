--!strict

--[[
	Returns a metadata object for the given itemId for use in UI presentation
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local ImageId = require(ReplicatedStorage.Source.SharedConstants.ImageId)
local ItemCategoryColor = require(ReplicatedStorage.Source.SharedConstants.ItemCategoryColor)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getCategoryForItemId = require(ReplicatedStorage.Source.Utility.Farm.getCategoryForItemId)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local findFirstChildWithAttribute = require(ReplicatedStorage.Source.Utility.findFirstChildWithAttribute)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

export type ItemMetadata = {
	name: string,
	iconId: number?,
	categoryId: ItemCategory.EnumType,
	descriptionShort: string,
	descriptionLong: string,
	itemModel: Model,
	secondaryModel: Model?,
	primaryColor: Color3,
	secondaryColor: Color3,
}

local function getMetadataFromItemId(itemId: string): ItemMetadata
	local categoryId: ItemCategory.EnumType = getCategoryForItemId(itemId)
	local itemModel = getItemByIdInCategory(itemId, categoryId)

	local name: string
	local iconId: number?
	local descriptionShort: string
	local descriptionLong: string
	local secondaryModel: Model?

	if categoryId == ItemCategory.CoinBundles then
		local bundleSize: number = getAttribute(itemModel, Attribute.CoinBundleSize)
		name = string.format(PlayerFacingString.Formats.CoinBundleShop.BundleName, bundleSize)
		iconId = ImageId.CoinIcon
		descriptionShort = ""
		descriptionLong = ""
	else
		name = getAttribute(itemModel, Attribute.DisplayName)
		descriptionShort = getAttribute(itemModel, Attribute.DescriptionShort)
		descriptionLong = getAttribute(itemModel, Attribute.DescriptionLong)
	end

	if categoryId == ItemCategory.Seeds then
		local plantSize: number = getAttribute(itemModel, Attribute.PlantSize)
		local potsFolder: Folder = getInstance(ReplicatedStorage, "Instances", "Pots")
		secondaryModel = findFirstChildWithAttribute(potsFolder, Attribute.MaxPlantSize, plantSize) :: Model?
	end

	local colors = ItemCategoryColor[categoryId]

	return {
		name = name,
		iconId = iconId,
		categoryId = categoryId,
		descriptionShort = descriptionShort,
		descriptionLong = descriptionLong,
		itemModel = itemModel,
		secondaryModel = secondaryModel,
		primaryColor = colors.Primary,
		secondaryColor = colors.Secondary,
	}
end

return getMetadataFromItemId
