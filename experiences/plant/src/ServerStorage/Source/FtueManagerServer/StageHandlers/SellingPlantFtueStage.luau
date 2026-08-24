--!strict

--[[
	Handles the SellingPlant stage during the First Time User Experience,
	which waits for the player to sell their wagon contents at the market
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FarmManagerServer = require(ServerStorage.Source.Farm.FarmManagerServer)
local Market = require(ServerStorage.Source.Market)
local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)

local SellingPlantFtueStage = {}

function SellingPlantFtueStage.handleAsync(player: Player): FtueStage.EnumType?
	local farm = FarmManagerServer.getFarmForPlayer(player)
	farm:openDoor()

	repeat
		local playerWhoSold = Market.plantsSold:Wait()
	until playerWhoSold == player

	return FtueStage.PurchasingSeed
end

return SellingPlantFtueStage
