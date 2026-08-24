--!strict

--[[
	Uses a ShopListSelector to create a garden store UI to purchase pots and tables with currency.
	Keeps the UI updated with the player's currency data and handles logic
	around when the sidebar button is enabled or disabled.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local ItemCategoryColor = require(ReplicatedStorage.Source.SharedConstants.ItemCategoryColor)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local ShopListSelector = require(ReplicatedStorage.Source.UI.UIComponents.ShopListSelector)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)

local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)

local LAYER_ID: UILayerId.EnumType = UILayerId.GardenStore

local listSelectorProperties = {
	primaryColor = ItemCategoryColor[ItemCategory.Pots].Primary,
	secondaryColor = ItemCategoryColor[ItemCategory.Pots].Secondary,
	title = PlayerFacingString.ListSelector.GardenStore.Title,
	footerDescription = PlayerFacingString.ListSelector.GardenStore.FooterDescription,
	itemIds = Freeze.List.concat(
		getSortedIdsInCategory(ItemCategory.Pots),
		getSortedIdsInCategory(ItemCategory.Tables)
	),
}

local UIGardenStore = {}
UIGardenStore._shopListSelector = ShopListSelector.new(listSelectorProperties)

function UIGardenStore.setup(parent: Instance)
	UIGardenStore._setupListSelector(parent)
	UIGardenStore._registerLayer()
end

function UIGardenStore.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

function UIGardenStore.getShopListSelector()
	return UIGardenStore._shopListSelector
end

function UIGardenStore._setupListSelector(parent: Instance)
	local listSelector = UIGardenStore._shopListSelector:getListSelector()
	listSelector:setParent(parent)
	listSelector.closed:Connect(function()
		UIHandler.hide(LAYER_ID)
	end)
end

function UIGardenStore._registerLayer()
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.Menu, UIGardenStore)

	visibilityChanged:Connect(function(isVisible: any)
		if isVisible :: boolean then
			UIGardenStore._shopListSelector:getListSelector():show()
		else
			UIGardenStore._shopListSelector:getListSelector():hide()
		end
	end)
end

return UIGardenStore
