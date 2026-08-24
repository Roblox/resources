--!strict

--[[
	Server-side manager that listens to events to advance the FTUE stage in a player's data and
	trigger server-side world changes according to the current stage
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local FtueAnalytics = require(ServerStorage.Source.Analytics.FtueAnalytics)
local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)
local InFarmFtueStage = require(script.StageHandlers.InFarmFtueStage)
local SellingPlantFtueStage = require(script.StageHandlers.SellingPlantFtueStage)
local PurchasingSeedFtueStage = require(script.StageHandlers.PurchasingSeedFtueStage)
local PurchasingPotFtueStage = require(script.StageHandlers.PurchasingPotFtueStage)
local ReturningToFarmFtueStage = require(script.StageHandlers.ReturningToFarmFtueStage)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

type FtueStageHandler = {
	handleAsync: (Player) -> FtueStage.EnumType?,
}

local handlerByStage: { [FtueStage.EnumType]: FtueStageHandler } = {
	[FtueStage.InFarm] = InFarmFtueStage,
	[FtueStage.SellingPlant] = SellingPlantFtueStage,
	[FtueStage.PurchasingSeed] = PurchasingSeedFtueStage,
	[FtueStage.PurchasingPot] = PurchasingPotFtueStage,
	[FtueStage.ReturningToFarm] = ReturningToFarmFtueStage,
}

local FtueManagerServer = {}

function FtueManagerServer.onPlayerAdded(player: Player)
	local ftueStage = PlayerDataServer.getValue(player, PlayerDataKey.FtueStage)
	FtueManagerServer._updateFtueStage(player, ftueStage)
end

function FtueManagerServer._updateFtueStage(player: Player, ftueStage: FtueStage.EnumType?)
	PlayerDataServer.setValue(player, PlayerDataKey.FtueStage, ftueStage)

	if not ftueStage then
		return
	end

	FtueAnalytics.logFtueStage(player, ftueStage)

	-- This is the last stage, so we don't have to perform any further actions
	if ftueStage == FtueStage.Complete then
		return
	end

	task.spawn(function()
		local stageHandler = handlerByStage[ftueStage :: FtueStage.EnumType]
		local nextStage: FtueStage.EnumType? = stageHandler.handleAsync(player)
		FtueManagerServer._updateFtueStage(player, nextStage)
	end)
end

return FtueManagerServer
