--!strict

--[[
	Uses an InventoryListSelector to show all of the player's items.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local InventoryListSelector = require(ReplicatedStorage.Source.UI.UIComponents.InventoryListSelector)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local ItemCategoryColor = require(ReplicatedStorage.Source.SharedConstants.ItemCategoryColor)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)

local LAYER_ID: UILayerId.EnumType = UILayerId.Inventory

local listSelectorProperties = {
	primaryColor = ItemCategoryColor[ItemCategory.Pots].Primary,
	secondaryColor = ItemCategoryColor[ItemCategory.Pots].Secondary,
	title = PlayerFacingString.ListSelector.Inventory.Title,
	footerDescription = PlayerFacingString.ListSelector.Inventory.FooterDescription,
	itemIds = Freeze.List.concat(
		getSortedIdsInCategory(ItemCategory.Seeds),
		getSortedIdsInCategory(ItemCategory.Pots),
		getSortedIdsInCategory(ItemCategory.Tables)
	),
}

local UIInventory = {}
UIInventory._inventoryListSelector = InventoryListSelector.new(listSelectorProperties)

function UIInventory.setup(parent: Instance)
	UIInventory._setupListSelector(parent)
	UIInventory._registerLayer()
end

function UIInventory.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

function UIInventory._registerLayer()
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.Menu, UIInventory)

	visibilityChanged:Connect(function(isVisible: any)
		if isVisible :: boolean then
			UIInventory._inventoryListSelector:getListSelector():show()
		else
			UIInventory._inventoryListSelector:getListSelector():hide()
		end
	end)
end

function UIInventory._setupListSelector(parent: Instance)
	local listSelector = UIInventory._inventoryListSelector:getListSelector()
	listSelector:setParent(parent)
	listSelector.closed:Connect(function()
		UIHandler.hide(LAYER_ID)
	end)

	-- The inventory screen is only for reviewing which items the player currently owns, and has no
	-- action functionality. For that reason, we will hide the action button in the sidebar
	listSelector:getSidebar():getActionButton():getInstance().Visible = false
end

return UIInventory
