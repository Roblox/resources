--!strict

--[[
	Uses a ShopListSelector to create a market UI to purchase any seed with currency.
	Keeps the UI updated with the player's currency data and handles logic
	around when the sidebar button is enabled or disabled.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local ShopListSelector = require(ReplicatedStorage.Source.UI.UIComponents.ShopListSelector)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local ItemCategoryColor = require(ReplicatedStorage.Source.SharedConstants.ItemCategoryColor)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)

local LAYER_ID: UILayerId.EnumType = UILayerId.SeedMarket

local listSelectorProperties = {
	primaryColor = ItemCategoryColor[ItemCategory.Seeds].Primary,
	secondaryColor = ItemCategoryColor[ItemCategory.Seeds].Secondary,
	title = PlayerFacingString.ListSelector.SeedMarket.Title,
	footerDescription = PlayerFacingString.ListSelector.SeedMarket.FooterDescription,
	itemIds = getSortedIdsInCategory(ItemCategory.Seeds),
}

local UISeedMarket = {}
UISeedMarket._shopListSelector = ShopListSelector.new(listSelectorProperties)

function UISeedMarket.setup(parent: Instance)
	UISeedMarket._setupListSelector(parent)
	UISeedMarket._registerLayer()
end

function UISeedMarket.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

function UISeedMarket._setupListSelector(parent: Instance)
	local listSelector = UISeedMarket._shopListSelector:getListSelector()
	listSelector:setParent(parent)
	listSelector.closed:Connect(function()
		UIHandler.hide(LAYER_ID)
	end)
end

function UISeedMarket._registerLayer()
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.Menu, UISeedMarket)

	visibilityChanged:Connect(function(isVisible: any)
		if isVisible :: boolean then
			UISeedMarket._shopListSelector:getListSelector():show()
		else
			UISeedMarket._shopListSelector:getListSelector():hide()
		end
	end)
end

function UISeedMarket.getShopListSelector()
	return UISeedMarket._shopListSelector
end

return UISeedMarket
