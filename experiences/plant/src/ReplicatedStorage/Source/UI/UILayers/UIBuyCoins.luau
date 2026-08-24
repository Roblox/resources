--!strict

--[[
	Uses a ListSelector to create a menu allowing the player to buy bundles of coins
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local ColorTheme = require(ReplicatedStorage.Source.SharedConstants.ColorTheme)
local ListSelector = require(ReplicatedStorage.Source.UI.UIComponents.ListSelector)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local ImageId = require(ReplicatedStorage.Source.SharedConstants.ImageId)
local DevProductPriceList = require(ReplicatedStorage.Source.DevProductPriceList)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)

local LAYER_ID: UILayerId.EnumType = UILayerId.BuyCoins

local localPlayer = Players.LocalPlayer :: Player

local listSelectorProperties = {
	primaryColor = ColorTheme.Green,
	secondaryColor = ColorTheme.LightGreen,
	title = PlayerFacingString.ListSelector.BuyCoins.Title,
	titleIconImageId = ImageId.CoinIcon,
	footerDescription = PlayerFacingString.ListSelector.BuyCoins.FooterDescription,
	itemIds = getSortedIdsInCategory(ItemCategory.CoinBundles),
}

local UIBuyCoins = {}
-- Although there is a ShopListSelector ListSelector variant, we are not using it here
-- as our purchasing logic is different (as it uses MarketplaceService)
UIBuyCoins._listSelector = ListSelector.new(listSelectorProperties)

function UIBuyCoins.setup(parent: Instance)
	UIBuyCoins._setupListSelector(parent)
	UIBuyCoins._setListItemAmounts()
	UIBuyCoins._registerLayer()
	UIBuyCoins._listenForSidebarActivated()
	UIBuyCoins._listenForSelectionChanged()
end

function UIBuyCoins._setupListSelector(parent: Instance)
	UIBuyCoins._listSelector:setParent(parent)

	UIBuyCoins._listSelector.closed:Connect(function()
		UIHandler.hide(LAYER_ID)
	end)
end

function UIBuyCoins._registerLayer()
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.Menu, UIBuyCoins)

	visibilityChanged:Connect(function(isVisible: any)
		if isVisible :: boolean then
			UIBuyCoins._listSelector:show()
		else
			UIBuyCoins._listSelector:hide()
		end
	end)
end

function UIBuyCoins._setListItemAmounts()
	for bundleId, listItem in pairs(UIBuyCoins._listSelector:getListItems()) do
		local bundleModel = getItemByIdInCategory(bundleId, ItemCategory.CoinBundles)
		local robuxCost = UIBuyCoins._getBundlePrice(bundleModel)
		listItem:setAmountText(string.format(PlayerFacingString.Formats.CoinBundleShop.ListItemCost, robuxCost))
	end
end

function UIBuyCoins._listenForSidebarActivated()
	local sidebar = UIBuyCoins._listSelector:getSidebar()
	local sidebarActionButton = sidebar:getActionButton():getButton()
	sidebarActionButton.activated:Connect(function()
		UIBuyCoins._onSidebarActivated()
	end)
end

function UIBuyCoins._listenForSelectionChanged()
	UIBuyCoins._listSelector.selectionChanged:Connect(function()
		UIBuyCoins._update()
	end)
end

function UIBuyCoins._getBundleTitle(bundleModel: Model)
	local bundleSize: number = getAttribute(bundleModel, Attribute.CoinBundleSize)
	return string.format(PlayerFacingString.Formats.CoinBundleShop.BundleName, bundleSize)
end

function UIBuyCoins._getBundlePrice(bundleModel: Model)
	local developerProductId: number = getAttribute(bundleModel, Attribute.DeveloperProductId)
	local robuxCost = DevProductPriceList.get(developerProductId)

	return robuxCost
end

function UIBuyCoins._update()
	-- Avoid updating UI and making connections for invisible UI, as it will get called again whenever it's made visible
	if not UIHandler.isVisible(LAYER_ID) then
		return
	end

	local listSelector = UIBuyCoins._listSelector
	local selectedBundleIdMaybe = listSelector:getSelectedId()
	-- As long as there are more than zero bundles for sale, selectedBundleId will be set
	-- but we will verify here to account for situations where no bundles are on sale
	if not selectedBundleIdMaybe then
		return
	end

	local selectedBundleId = selectedBundleIdMaybe :: string

	local sidebar = listSelector:getSidebar()
	local actionButton = sidebar:getActionButton()

	-- Update sidebar
	local bundleModel = getItemByIdInCategory(selectedBundleId, ItemCategory.CoinBundles)
	local robuxCost = UIBuyCoins._getBundlePrice(bundleModel)
	local actionButtonText = string.format(PlayerFacingString.Formats.CoinBundleShop.ActionButtonText, robuxCost)

	sidebar:setInfo(selectedBundleId)
	actionButton:setText(actionButtonText)
	actionButton:setEnabled(true)
	sidebar:setFooterText(nil)
end

function UIBuyCoins._onSidebarActivated()
	local listSelector = UIBuyCoins._listSelector
	local selectedBundleIdMaybe = listSelector:getSelectedId()
	-- As long as there are more than zero bundles for sale, selectedBundleId will be set
	-- but we will verify here to account for situations where no bundles are on sale
	if not selectedBundleIdMaybe then
		return
	end
	local selectedBundleId = selectedBundleIdMaybe :: string

	local bundleModel = getItemByIdInCategory(selectedBundleId, ItemCategory.CoinBundles)
	local developerProductId: number = getAttribute(bundleModel, Attribute.DeveloperProductId)
	local closeButton = listSelector:getCloseButton()
	local actionButton = listSelector:getSidebar():getActionButton()

	closeButton:setEnabled(false)
	actionButton:setEnabled(false)
	listSelector:setAllListItemsEnabled(false)

	local promptFinishedConnection
	promptFinishedConnection = MarketplaceService.PromptProductPurchaseFinished:Connect(function()
		promptFinishedConnection:Disconnect()
		closeButton:setEnabled(true)
		actionButton:setEnabled(true)
		listSelector:setAllListItemsEnabled(true)
	end)

	MarketplaceService:PromptProductPurchase(localPlayer, developerProductId)
end

function UIBuyCoins.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

function UIBuyCoins.getListSelector()
	return UIBuyCoins._listSelector
end

return UIBuyCoins
