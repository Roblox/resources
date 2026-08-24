--!strict

--[[
	Uses a InventoryListSelector to prompt the player to choose from a list of their owned pots
	to place on a table. Keeps the UI updated with the player's "owned pots" data and handles logic
	around when the sidebar button is enabled or disabled.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local InventoryListSelector = require(ReplicatedStorage.Source.UI.UIComponents.InventoryListSelector)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local ItemCategoryColor = require(ReplicatedStorage.Source.SharedConstants.ItemCategoryColor)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)
local getMetadataFromItemId = require(ReplicatedStorage.Source.Utility.Farm.getMetadataFromItemId)
local getItemAmountInInventory = require(ReplicatedStorage.Source.Utility.PlayerData.getItemAmountInInventory)

local LAYER_ID: UILayerId.EnumType = UILayerId.PlacePot

local listSelectorProperties = {
	primaryColor = ItemCategoryColor[ItemCategory.Pots].Primary,
	secondaryColor = ItemCategoryColor[ItemCategory.Pots].Secondary,
	title = PlayerFacingString.ListSelector.PlacePot.Title,
	footerDescription = PlayerFacingString.ListSelector.PlacePot.FooterDescription,
	itemIds = getSortedIdsInCategory(ItemCategory.Pots),
}

local UIPlacePot = {}
UIPlacePot._inventoryListSelector = InventoryListSelector.new(listSelectorProperties)
UIPlacePot._selectedSpotModel = nil :: Model?

function UIPlacePot.setup(parent: Instance)
	UIPlacePot._setupListSelector(parent)

	UIPlacePot._registerLayer()
	UIPlacePot._listenForSidebarActivated()
end

function UIPlacePot._registerLayer()
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.Menu, UIPlacePot)

	visibilityChanged:Connect(function(isVisible: any)
		if isVisible :: boolean then
			UIPlacePot._inventoryListSelector:getListSelector():show()
		else
			UIPlacePot._inventoryListSelector:getListSelector():hide()
		end
	end)
end

function UIPlacePot._setupListSelector(parent: Instance)
	local listSelector = UIPlacePot._inventoryListSelector:getListSelector()
	listSelector:setParent(parent)

	listSelector.closed:Connect(function()
		UIHandler.hide(LAYER_ID)
	end)

	UIPlacePot._inventoryListSelector.updated:Connect(function()
		UIPlacePot._update()
	end)
end

function UIPlacePot._update()
	-- Avoid updating UI and making connections for invisible UI, as it will get called again whenever it's made visible
	if not UIHandler.isVisible(LAYER_ID) then
		return
	end

	local listSelector = UIPlacePot._inventoryListSelector:getListSelector()
	local itemIdMaybe = listSelector:getSelectedId()
	local sidebar = listSelector:getSidebar()

	if not itemIdMaybe then
		-- This happens if a player owns no seeds or ran out of the last selected seed type
		-- TODO: Does it still?
		return
	end
	local itemId = itemIdMaybe :: string

	assert(UIPlacePot._selectedSpotModel, "UIPlacePot has no Spot defined")

	local itemMetadata = getMetadataFromItemId(itemId)
	local hasPotInInventory = getItemAmountInInventory(itemId) > 0

	local actionButtonText =
		string.format(PlayerFacingString.Formats.ItemPlacement.PlaceActionButtonText, itemMetadata.name:upper())

	local actionButton = sidebar:getActionButton()
	actionButton:setText(actionButtonText)
	actionButton:setEnabled(hasPotInInventory)
end

function UIPlacePot.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

function UIPlacePot.setSpotModel(spotModel: Model)
	UIPlacePot._selectedSpotModel = spotModel
	UIPlacePot._update()
end

function UIPlacePot._listenForSidebarActivated()
	local sidebar = UIPlacePot._inventoryListSelector:getListSelector():getSidebar()
	local sidebarActionButton = sidebar:getActionButton():getButton()
	sidebarActionButton.activated:Connect(function()
		UIPlacePot._onSidebarActivated()
	end)
end

function UIPlacePot._onSidebarActivated()
	local listSelector = UIPlacePot._inventoryListSelector:getListSelector()
	-- TODO: Switch to remote function & show error messages to player
	Network.fireServer(
		Network.RemoteEvents.RequestPlaceObject,
		UIPlacePot._selectedSpotModel,
		listSelector:getSelectedId()
	)

	UIHandler.hide(LAYER_ID)
end

return UIPlacePot
