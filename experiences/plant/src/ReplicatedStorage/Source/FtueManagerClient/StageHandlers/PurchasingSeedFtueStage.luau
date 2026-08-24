--!strict

--[[
	Handles the client-side PurchasingSeed stage during the First Time User Experience,
	which disables all vendors except the store to buy a seed
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local UIHighlight = require(ReplicatedStorage.Source.UI.UIComponents.UIHighlight)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local CharacterPath = require(ReplicatedStorage.Source.CharacterPath)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local Signal = require(ReplicatedStorage.Source.Signal)
local setVendorEnabled = require(ReplicatedStorage.Source.Utility.Farm.setVendorEnabled)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)

local gardenSupplyVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "GardenSupply")
local marketVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Market")
local storeVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Store")

local SEED_CABBAGE_ITEM_ID = "SeedCabbage"

local allSeeds = getSortedIdsInCategory(ItemCategory.Seeds)

local PurchasingSeedFtueStage = {}
PurchasingSeedFtueStage._characterPath = nil :: CharacterPath.ClassType?
PurchasingSeedFtueStage._purchaseUiHighlight = nil :: UIHighlight.ClassType?
PurchasingSeedFtueStage._updatedConnection = nil :: Signal.SignalConnection?

function PurchasingSeedFtueStage.setup()
	setVendorEnabled(gardenSupplyVendor, false)
	setVendorEnabled(marketVendor, false)
	setVendorEnabled(storeVendor, true)

	local primaryPart = storeVendor.PrimaryPart :: BasePart
	local beamAttachment: Attachment = getInstance(primaryPart, "FtueBeamAttachment1")
	PurchasingSeedFtueStage._characterPath = CharacterPath.new(beamAttachment)
	PurchasingSeedFtueStage._highlightPurchaseSeedButton()
end

function PurchasingSeedFtueStage._highlightPurchaseSeedButton()
	local seedMarketUiLayer = UIHandler.getLayerClassInstanceById(UILayerId.SeedMarket)
	local shopListSelector = seedMarketUiLayer:getShopListSelector()
	local listSelector = shopListSelector:getListSelector()
	local sidebarActionButton = listSelector:getSidebar():getActionButton():getInstance()

	PurchasingSeedFtueStage._purchaseUiHighlight = UIHighlight.new(sidebarActionButton)

	-- Disable every item apart from the seed
	local allSeedsExceptCabbage = Freeze.List.removeValue(allSeeds, SEED_CABBAGE_ITEM_ID)
	shopListSelector:setDisabledItemIds(allSeedsExceptCabbage)
end

function PurchasingSeedFtueStage._highlightCloseButton()
	if UIHandler.isVisible(UILayerId.SeedMarket) then
		local seedMarketUiLayer = UIHandler.getLayerClassInstanceById(UILayerId.SeedMarket)
		local shopListSelector = seedMarketUiLayer:getShopListSelector()
		local listSelector = shopListSelector:getListSelector()
		local closeButton = listSelector:getCloseButton():getInstance()
		local closeUiHighlight = UIHighlight.new(closeButton)

		-- Disable every item
		shopListSelector:setDisabledItemIds(allSeeds)

		listSelector.closed:Wait()
		closeUiHighlight:destroy()
	end
end

function PurchasingSeedFtueStage.teardown()
	if PurchasingSeedFtueStage._characterPath then
		PurchasingSeedFtueStage._characterPath:destroy()
	end
	if PurchasingSeedFtueStage._purchaseUiHighlight then
		PurchasingSeedFtueStage._purchaseUiHighlight:destroy()
	end
	PurchasingSeedFtueStage._highlightCloseButton()

	-- Re-enable every item
	local seedMarketUiLayer = UIHandler.getLayerClassInstanceById(UILayerId.SeedMarket)
	local shopListSelector = seedMarketUiLayer:getShopListSelector()
	shopListSelector:setDisabledItemIds({})
end

return PurchasingSeedFtueStage
