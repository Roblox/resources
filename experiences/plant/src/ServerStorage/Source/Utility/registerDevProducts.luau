--!strict

--[[
	Registers developer products to the ReceiptProcessor and starts listening for purchases
	being made.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ReceiptProcessor = require(ServerStorage.Source.ReceiptProcessor)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local EconomyAnalytics = require(ServerStorage.Source.Analytics.EconomyAnalytics)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)

local function registerDevProducts()
	local coinBundleIds = getSortedIdsInCategory(ItemCategory.CoinBundles)

	for _, coinBundleId in ipairs(coinBundleIds) do
		local bundleModel = getItemByIdInCategory(coinBundleId, ItemCategory.CoinBundles)

		local developerProductId: number = getAttribute(bundleModel, Attribute.DeveloperProductId)
		local bundleSize: number = getAttribute(bundleModel, Attribute.CoinBundleSize)

		ReceiptProcessor.registerProductCallback(developerProductId, function(player: Player)
			PlayerDataServer.updateValue(player, PlayerDataKey.Coins, function(oldValueMaybe: number?)
				local oldValue: number = oldValueMaybe or 0

				return oldValue + bundleSize
			end)

			local endingBalance = PlayerDataServer.getValue(player, PlayerDataKey.Coins)
			EconomyAnalytics.logBundlePurchased(player, coinBundleId, bundleSize, endingBalance)
		end)
	end

	ReceiptProcessor.start()
end

return registerDevProducts
