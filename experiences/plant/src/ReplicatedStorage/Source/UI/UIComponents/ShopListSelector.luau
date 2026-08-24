--!strict

--[[
	A wrapper for ListSelector that acts as a base class for 'Shop' List Selector UI layers, including:
	 - UISeedMarket
	 - UIGardenStore

	The following functionality is appended to ListSelector:
	 - Hooking up the action button to make a purchase request
	 - Showing the price of the ListItems
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ListSelector = require(ReplicatedStorage.Source.UI.UIComponents.ListSelector)
local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local ImageId = require(ReplicatedStorage.Source.SharedConstants.ImageId)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local MarketClient = require(ReplicatedStorage.Source.MarketClient)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local Connections = require(ReplicatedStorage.Source.Connections)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getPurchaseCost = require(ReplicatedStorage.Source.Utility.Farm.getPurchaseCost)
local getCategoryForItemId = require(ReplicatedStorage.Source.Utility.Farm.getCategoryForItemId)
local getItemAmountInInventory = require(ReplicatedStorage.Source.Utility.PlayerData.getItemAmountInInventory)

export type ListSelectorProperties = ListSelector.ListSelectorProperties

local ShopListSelector = {}
ShopListSelector.__index = ShopListSelector

export type ClassType = typeof(setmetatable(
	{} :: {
		_listSelector: ListSelector.ClassType,
		_connections: Connections.ClassType,
		_purchasePending: boolean,
		_disabledItemIds: { string },
	},
	ShopListSelector
))

function ShopListSelector.new(listSelectorProperties: ListSelector.ListSelectorProperties): ClassType
	local self = {
		_listSelector = ListSelector.new(listSelectorProperties),
		_connections = Connections.new(),
		_purchasePending = false,
		_disabledItemIds = {},
	}
	setmetatable(self, ShopListSelector)

	self:_setup()

	return self
end

function ShopListSelector.setDisabledItemIds(self: ClassType, itemIds: { string })
	self._disabledItemIds = itemIds
	self:_update()
end

function ShopListSelector._setup(self: ClassType)
	local dataConnection = PlayerDataClient.updated:Connect(function(valueName: any)
		if valueName :: string ~= PlayerDataKey.Coins and valueName ~= PlayerDataKey.Inventory then
			return
		end
		self:_update()
	end)

	local selectionConnection = self._listSelector.selectionChanged:Connect(function()
		self:_update()
	end)

	self._connections:add(dataConnection, selectionConnection)

	self:_setListItems()
	self:_listenForSidebarActivated()
end

function ShopListSelector._setListItems(self: ClassType)
	for itemId, listItem in pairs(self._listSelector:getListItems()) do
		local purchaseCost = getPurchaseCost(itemId)
		local amountText = string.format(PlayerFacingString.Formats.Shop.ListItemCost, purchaseCost)

		listItem:setAmountText(amountText)
	end
end

function ShopListSelector._listenForSidebarActivated(self: ClassType)
	local sidebar = self._listSelector:getSidebar()
	local sidebarActionButton = sidebar:getActionButton():getButton()
	sidebarActionButton.activated:Connect(function()
		self:_onSidebarActivated()
	end)
end

function ShopListSelector._updateListItems(self: ClassType)
	local listItems = self._listSelector:getListItems()

	for listItemId, listItem in pairs(listItems) do
		local enable = true
		local isItemIdDisabled = table.find(self._disabledItemIds, listItemId)
		if self._purchasePending or isItemIdDisabled then
			enable = false
		end

		listItem:setEnabled(enable)
	end
end

function ShopListSelector._updateActionButton(self: ClassType)
	local actionButton = self._listSelector:getSidebar():getActionButton()
	local selectedItemId = self._listSelector:getSelectedId()

	local enableActionButton = false

	if selectedItemId and not self._purchasePending then
		if not table.find(self._disabledItemIds, selectedItemId) then
			enableActionButton = true
		end
	end

	if enableActionButton then
		local purchaseCost = getPurchaseCost(selectedItemId :: string)
		local playerCurrency = PlayerDataClient.get(PlayerDataKey.Coins) or 0
		local canAfford = playerCurrency >= purchaseCost

		if canAfford then
			local actionButtonText = string.format(PlayerFacingString.Formats.Shop.ActionButtonText, purchaseCost)
			actionButton:setText(actionButtonText, ImageId.CoinIcon)
		else
			actionButton:setText(PlayerFacingString.Formats.Shop.BuyMoreCurrency, ImageId.CoinIcon)
		end

		actionButton:setEnabled(true)
	else
		actionButton:setEnabled(false)
	end
end

function ShopListSelector._updateSidebar(self: ClassType)
	local listSelector = self._listSelector
	local sidebar = listSelector:getSidebar()

	local selectedItemIdMaybe = listSelector:getSelectedId()
	if not selectedItemIdMaybe then
		sidebar:reset()
		return
	end
	local selectedItemId = selectedItemIdMaybe :: string

	local numOwned = getItemAmountInInventory(selectedItemId)
	sidebar:setFooterText(tostring(numOwned))
	sidebar:setInfo(selectedItemId)
end

function ShopListSelector._update(self: ClassType)
	-- Avoid updating UI and making connections for invisible UI, as it will get called again whenever it's made visible
	if not self._listSelector:isVisible() then
		return
	end

	self:_updateListItems()
	self:_updateActionButton()
	self:_updateSidebar()
end

function ShopListSelector._onSidebarActivated(self: ClassType)
	local selectedItemIdMaybe = self._listSelector:getSelectedId()

	if not selectedItemIdMaybe then
		return
	end
	local selectedItemId = selectedItemIdMaybe :: string

	local purchaseCost = getPurchaseCost(selectedItemId)
	local playerCurrency = PlayerDataClient.get(PlayerDataKey.Coins) or 0
	local canAfford = playerCurrency >= purchaseCost

	-- If the player can't afford the item, we'll redirect them to the buy coins page
	if not canAfford then
		UIHandler.show(UILayerId.BuyCoins)
		return
	end

	self._purchasePending = true
	self:_update()

	-- TODO: Consider adding variable amount to client UI (to buy multiple seeds at once)
	local amount = 1
	local purchaseGranted, result =
		MarketClient.requestItemPurchaseAsync(selectedItemId, getCategoryForItemId(selectedItemId), amount)

	self._purchasePending = false
	self:_update()

	-- TODO: Show error or success message on purchase
	print("Purchase", selectedItemId, "result:", purchaseGranted, result)
end

function ShopListSelector.getListSelector(self: ClassType)
	return self._listSelector
end

function ShopListSelector.destroy(self: ClassType)
	self._listSelector:destroy()
	self._connections:disconnect()
end

return ShopListSelector
