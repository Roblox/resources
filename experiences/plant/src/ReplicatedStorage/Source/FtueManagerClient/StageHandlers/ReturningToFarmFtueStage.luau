--!strict

--[[
	Handles the client-side ReturningTOFarm stage during the First Time User Experience,
	which enables all vendors and creates a path pointing to their farm
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local CharacterPath = require(ReplicatedStorage.Source.CharacterPath)
local setVendorEnabled = require(ReplicatedStorage.Source.Utility.Farm.setVendorEnabled)
local getFarmModelFromOwnerId = require(ReplicatedStorage.Source.Utility.Farm.getFarmModelFromOwnerId)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local gardenSupplyVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "GardenSupply")
local marketVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Market")
local storeVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Store")

local localPlayer = Players.LocalPlayer :: Player

local ReturningToFarmFtueStage = {}
ReturningToFarmFtueStage._characterPath = nil :: CharacterPath.ClassType?

function ReturningToFarmFtueStage.setup()
	-- TODO: Use UIHighlight on sidebar action buttons
	local farmModel = getFarmModelFromOwnerId(localPlayer.UserId)
	assert(farmModel, "Cannot start Ftue stage before farm has loaded")
	setVendorEnabled(gardenSupplyVendor, true)
	setVendorEnabled(marketVendor, true)
	setVendorEnabled(storeVendor, true)

	local primaryPart = farmModel.PrimaryPart :: BasePart
	local beamAttachment: Attachment = getInstance(primaryPart, "FarmAttachment")
	ReturningToFarmFtueStage._characterPath = CharacterPath.new(beamAttachment)
end

function ReturningToFarmFtueStage.teardown()
	if ReturningToFarmFtueStage._characterPath then
		ReturningToFarmFtueStage._characterPath:destroy()
	end
end

return ReturningToFarmFtueStage
