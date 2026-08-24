--!strict

--[[
	Handles the client-side PurchasingPot stage during the First Time User Experience,
	which disables all vendors except the garden supply to buy a pot
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local UIHighlight = require(ReplicatedStorage.Source.UI.UIComponents.UIHighlight)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local CharacterPath = require(ReplicatedStorage.Source.CharacterPath)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local setVendorEnabled = require(ReplicatedStorage.Source.Utility.Farm.setVendorEnabled)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)

local gardenSupplyVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "GardenSupply")
local marketVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Market")
local storeVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Store")

local SMALL_POT_ITEM_ID = "SmallPot"

local allGardenStoreItems =
	Freeze.List.concat(getSortedIdsInCategory(ItemCategory.Pots), getSortedIdsInCategory(ItemCategory.Tables))

local PurchasingPotFtueStage = {}
PurchasingPotFtueStage._characterPath = nil :: CharacterPath.ClassType?
PurchasingPotFtueStage._purchaseUiHighlight = nil :: UIHighlight.ClassType?

function PurchasingPotFtueStage.setup()
	setVendorEnabled(gardenSupplyVendor, true)
	setVendorEnabled(marketVendor, false)
	setVendorEnabled(storeVendor, false)

	local primaryPart = gardenSupplyVendor.PrimaryPart :: BasePart
	local beamAttachment: Attachment = getInstance(primaryPart, "FtueBeamAttachment1")
	PurchasingPotFtueStage._characterPath = CharacterPath.new(beamAttachment)
	PurchasingPotFtueStage._highlightPurchasePotButton()
end

function PurchasingPotFtueStage._highlightPurchasePotButton()
	local gardenStoreUiLayer = UIHandler.getLayerClassInstanceById(UILayerId.GardenStore)
	local shopListSelector = gardenStoreUiLayer:getShopListSelector()
	local listSelector = shopListSelector:getListSelector()
	local sidebarActionButton = listSelector:getSidebar():getActionButton():getInstance()

	PurchasingPotFtueStage._purchaseUiHighlight = UIHighlight.new(sidebarActionButton)

	-- Disable every item apart from the small pot
	local allItemsExceptSmallPot = Freeze.List.removeValue(allGardenStoreItems, SMALL_POT_ITEM_ID)
	shopListSelector:setDisabledItemIds(allItemsExceptSmallPot)
end

function PurchasingPotFtueStage._highlightCloseButton()
	if UIHandler.isVisible(UILayerId.GardenStore) then
		local gardenStoreUiLayer = UIHandler.getLayerClassInstanceById(UILayerId.GardenStore)
		local shopListSelector = gardenStoreUiLayer:getShopListSelector()
		local listSelector = shopListSelector:getListSelector()
		local closeButton = listSelector:getCloseButton():getInstance()
		local closeUiHighlight = UIHighlight.new(closeButton)

		-- Disable every item
		shopListSelector:setDisabledItemIds(allGardenStoreItems)

		listSelector.closed:Wait()
		closeUiHighlight:destroy()
	end
end

function PurchasingPotFtueStage.teardown()
	if PurchasingPotFtueStage._characterPath then
		PurchasingPotFtueStage._characterPath:destroy()
	end
	if PurchasingPotFtueStage._purchaseUiHighlight then
		PurchasingPotFtueStage._purchaseUiHighlight:destroy()
	end
	PurchasingPotFtueStage._highlightCloseButton()

	-- Reset the exclusively enabled item ids
	local gardenStoreUiLayer = UIHandler.getLayerClassInstanceById(UILayerId.GardenStore)
	local shopListSelector = gardenStoreUiLayer:getShopListSelector()

	-- Re-enable every item
	shopListSelector:setDisabledItemIds({})
end

return PurchasingPotFtueStage
