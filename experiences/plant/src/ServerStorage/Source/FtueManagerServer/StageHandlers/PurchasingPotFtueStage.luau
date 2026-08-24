--!strict

--[[
	Handles the PurchasingPot stage during the First Time User Experience,
	which waits for the player to purchase a pot
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FarmManagerServer = require(ServerStorage.Source.Farm.FarmManagerServer)
local Market = require(ServerStorage.Source.Market)
local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

local PurchasingPotFtueStage = {}

function PurchasingPotFtueStage.handleAsync(player: Player): FtueStage.EnumType?
	local farm = FarmManagerServer.getFarmForPlayer(player)
	farm:openDoor()

	repeat
		local playerWhoBought, _, itemCategory = Market.itemsPurchased:Wait()
	until playerWhoBought == player and itemCategory == ItemCategory.Pots

	return FtueStage.ReturningToFarm
end

return PurchasingPotFtueStage
