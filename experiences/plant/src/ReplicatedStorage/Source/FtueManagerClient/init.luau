--!strict

--[[
	Client-side manager that listens to the FTUE stage in a player's data to show hints to the player
	about what to do in the current stage and handle client-side effects
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)
local InFarmFtueStage = require(script.StageHandlers.InFarmFtueStage)
local SellingPlantFtueStage = require(script.StageHandlers.SellingPlantFtueStage)
local PurchasingSeedFtueStage = require(script.StageHandlers.PurchasingSeedFtueStage)
local PurchasingPotFtueStage = require(script.StageHandlers.PurchasingPotFtueStage)
local ReturningToFarmFtueStage = require(script.StageHandlers.ReturningToFarmFtueStage)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

type Stage = any -- TODO: Is there a way to specify a generic stage type containing setup and teardown?

local handlerByStage: { [string]: Stage } = {
	[FtueStage.InFarm] = InFarmFtueStage,
	[FtueStage.SellingPlant] = SellingPlantFtueStage,
	[FtueStage.PurchasingSeed] = PurchasingSeedFtueStage,
	[FtueStage.PurchasingPot] = PurchasingPotFtueStage,
	[FtueStage.ReturningToFarm] = ReturningToFarmFtueStage,
}

local FtueManagerClient = {}
FtueManagerClient.activeStage = nil :: Stage?

function FtueManagerClient.start()
	local ftueStage = PlayerDataClient.get(PlayerDataKey.FtueStage)
	FtueManagerClient._onFtueStageUpdated(ftueStage)
	PlayerDataClient.updated:Connect(function(valueName: any, value: any)
		if valueName :: string ~= PlayerDataKey.FtueStage then
			return
		end

		FtueManagerClient._onFtueStageUpdated(value)
	end)
end

function FtueManagerClient._onFtueStageUpdated(ftueStage: FtueStage.EnumType?)
	if FtueManagerClient.activeStage then
		FtueManagerClient.activeStage.teardown()
	end

	FtueManagerClient.activeStage = ftueStage and handlerByStage[ftueStage]

	if FtueManagerClient.activeStage then
		FtueManagerClient.activeStage.setup()
	end
end

return FtueManagerClient
