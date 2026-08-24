--!strict

--[[
	Uses a InventoryListSelector to prompt the player to choose from a list of their owned plants
	to plant inside a pot. Keeps the UI updated with the player's "owned plants" data and handles logic
	around when the sidebar button is enabled or disabled.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Network = require(ReplicatedStorage.Source.Network)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local InventoryListSelector = require(ReplicatedStorage.Source.UI.UIComponents.InventoryListSelector)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local ItemCategoryColor = require(ReplicatedStorage.Source.SharedConstants.ItemCategoryColor)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)
local checkSeedFitsInPot = require(ReplicatedStorage.Source.Utility.Farm.checkSeedFitsInPot)
local getItemAmountInInventory = require(ReplicatedStorage.Source.Utility.PlayerData.getItemAmountInInventory)
local getMetadataFromItemId = require(ReplicatedStorage.Source.Utility.Farm.getMetadataFromItemId)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local LAYER_ID: UILayerId.EnumType = UILayerId.PlantSeed

local plantSoundEffect: Sound = getInstance(SoundService, "SoundEffects", "Plant")
local listSelectorProperties: InventoryListSelector.ListSelectorProperties = {
	primaryColor = ItemCategoryColor[ItemCategory.Seeds].Primary,
	secondaryColor = ItemCategoryColor[ItemCategory.Seeds].Secondary,
	title = PlayerFacingString.ListSelector.PlantSeed.Title,
	footerDescription = PlayerFacingString.ListSelector.PlantSeed.FooterDescription,
	itemIds = getSortedIdsInCategory(ItemCategory.Seeds),
}

local UIPlantSeed = {}
UIPlantSeed._inventoryListSelector = InventoryListSelector.new(listSelectorProperties)
UIPlantSeed._selectedPotModel = nil :: Model?

function UIPlantSeed.setup(parent: Instance)
	UIPlantSeed._setupListSelector(parent)
	UIPlantSeed._registerLayer()
	UIPlantSeed._listenForSidebarActivated()
end

function UIPlantSeed._update()
	-- Avoid updating UI and making connections for invisible UI, as it will get called again whenever it's made visible
	if not UIHandler.isVisible(LAYER_ID) then
		return
	end

	local listSelector = UIPlantSeed._inventoryListSelector:getListSelector()
	local itemIdMaybe = listSelector:getSelectedId()
	local sidebar = listSelector:getSidebar()

	if not itemIdMaybe then
		-- This happens if a player owns no seeds or ran out of the last selected seed type
		-- TODO: Does it still?
		return
	end

	local itemId = itemIdMaybe :: string

	assert(UIPlantSeed._selectedPotModel, "UIPlantSeed has no Pot defined")

	local itemMetadata = getMetadataFromItemId(itemId)
	local hasSeedsInInventory = getItemAmountInInventory(itemId) > 0
	local plantFitsInPot = checkSeedFitsInPot(itemId, UIPlantSeed._selectedPotModel.Name)

	local actionButtonText = if plantFitsInPot
		then string.format(PlayerFacingString.Formats.ItemPlacement.PlantActionButtonText, itemMetadata.name:upper())
		else PlayerFacingString.Formats.ItemPlacement.NeedsLargerPot

	local actionButton = sidebar:getActionButton()
	actionButton:setText(actionButtonText)
	actionButton:setEnabled(hasSeedsInInventory and plantFitsInPot)
end

function UIPlantSeed._setupListSelector(parent: Instance)
	local listSelector = UIPlantSeed._inventoryListSelector:getListSelector()
	listSelector:setParent(parent)
	listSelector.closed:Connect(function()
		UIHandler.hide(LAYER_ID)
	end)

	UIPlantSeed._inventoryListSelector.updated:Connect(function()
		UIPlantSeed._update()
	end)
end

function UIPlantSeed._registerLayer()
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.Menu, UIPlantSeed)

	visibilityChanged:Connect(function(isVisible: any)
		if isVisible :: boolean then
			UIPlantSeed._inventoryListSelector:getListSelector():show()
		else
			UIPlantSeed._inventoryListSelector:getListSelector():hide()
		end
	end)
end

function UIPlantSeed.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

function UIPlantSeed.getInventoryListSelector()
	return UIPlantSeed._inventoryListSelector
end

function UIPlantSeed.setPotModel(potModel: Model)
	UIPlantSeed._selectedPotModel = potModel
	UIPlantSeed._update()
end

function UIPlantSeed._listenForSidebarActivated()
	local sidebar = UIPlantSeed._inventoryListSelector:getListSelector():getSidebar()
	local sidebarActionButton = sidebar:getActionButton():getButton()
	sidebarActionButton.activated:Connect(function()
		UIPlantSeed._onSidebarActivated()
	end)
end

function UIPlantSeed._onSidebarActivated()
	plantSoundEffect:Play()
	local selectedItemId = UIPlantSeed._inventoryListSelector:getListSelector():getSelectedId()
	-- TODO: Switch to remote function & show error messages to player
	Network.fireServer(Network.RemoteEvents.RequestPlantSeed, UIPlantSeed._selectedPotModel, selectedItemId)

	UIHandler.hide(LAYER_ID)
end

return UIPlantSeed
