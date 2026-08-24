--!strict

--[[
	Handles the client-side SellingPlant stage during the First Time User Experience,
	which disables all vendors except the market to sell your plant, and creates a path pointing to the market vendor
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CharacterPath = require(ReplicatedStorage.Source.CharacterPath)
local setVendorEnabled = require(ReplicatedStorage.Source.Utility.Farm.setVendorEnabled)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local gardenSupplyVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "GardenSupply")
local marketVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Market")
local storeVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Store")

local SellingPlantFtueStage = {}
SellingPlantFtueStage._characterPath = nil :: CharacterPath.ClassType?

function SellingPlantFtueStage.setup()
	-- TODO: Use UIHighlight on sidebar action buttons
	setVendorEnabled(gardenSupplyVendor, false)
	setVendorEnabled(marketVendor, true)
	setVendorEnabled(storeVendor, false)

	local primaryPart = marketVendor.PrimaryPart :: BasePart
	local beamAttachment: Attachment = getInstance(primaryPart, "FtueBeamAttachment1")
	SellingPlantFtueStage._characterPath = CharacterPath.new(beamAttachment)
end

function SellingPlantFtueStage.teardown()
	if SellingPlantFtueStage._characterPath then
		SellingPlantFtueStage._characterPath:destroy()
	end
end

return SellingPlantFtueStage
