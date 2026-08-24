--!strict

--[[
	Server-side handling for market operations, like updating player data
	when selling and buying plant seeds
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local EconomyAnalytics = require(ServerStorage.Source.Analytics.EconomyAnalytics)
local Signal = require(ReplicatedStorage.Source.Signal)
local Network = require(ReplicatedStorage.Source.Network)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local CustomAnalytics = require(ServerStorage.Source.Analytics.CustomAnalytics)
local ItemPurchaseFailureReason =
	require(ReplicatedStorage.Source.SharedConstants.RequestFailureReason.ItemPurchaseFailureReason)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)

local t = Network.t
local RemoteFunctions = Network.RemoteFunctions

local Market = {}
Market.plantsSold = Signal.new()
Market.itemsPurchased = Signal.new()

function Market.start()
	Network.bindFunction(RemoteFunctions.RequestItemPurchase, function(...)
		return Market._onRequestItemPurchase(...)
	end, t.tuple(t.instanceOf("Player"), t.string, t.string, t.intersection(t.integer, t.numberPositive)))
end

function Market.sellPlants(player: Player, plantIds: { string })
	assert(PlayerDataServer.hasLoaded(player), "Player attempted to sell plants before data was loaded")

	local totalSaleValue = 0

	for _, plantId in ipairs(plantIds) do
		local plantPrefab = getItemByIdInCategory(plantId, ItemCategory.Plants)
		local harvestValue: number = getAttribute(plantPrefab, Attribute.HarvestValue)

		totalSaleValue += harvestValue
	end

	PlayerDataServer.updateValue(player, PlayerDataKey.Coins, function(oldValueMaybe: number?)
		local oldValue: number = oldValueMaybe or 0

		return oldValue + totalSaleValue
	end)

	local endingBalance = PlayerDataServer.getValue(player, PlayerDataKey.Coins)
	for _, plantId in ipairs(plantIds) do
		local plantPrefab = getItemByIdInCategory(plantId, ItemCategory.Plants)
		local harvestValue: number = getAttribute(plantPrefab, Attribute.HarvestValue)

		EconomyAnalytics.logHarvestSold(player, plantId, endingBalance, harvestValue)
	end

	CustomAnalytics.logHarvestSold(player, #plantIds)

	Market.plantsSold:Fire(player, plantIds)
end

function Market._onRequestItemPurchase(
	player: Player,
	itemId: string,
	itemCategory: ItemCategory.EnumType,
	amount: number
): (boolean, ItemPurchaseFailureReason.EnumType?)
	assert(PlayerDataServer.hasLoaded(player), "Player attempted to purchase plants before data was loaded")

	if not ItemCategory[itemCategory] then
		return false, ItemPurchaseFailureReason.InvalidItemCategory
	end

	local success, result = pcall(getItemByIdInCategory, itemId, itemCategory)
	if not success then
		warn(string.format("Erroneous purchase request from %s: %s", player.Name, result :: any))
		return false, ItemPurchaseFailureReason.InvalidItemId
	end

	local plantModel = result

	-- TODO: Add purchase limit (prevent buying more tables/pots than you can use)
	local purchaseCost: number = getAttribute(plantModel, Attribute.PurchaseCost)
	local totalCost = purchaseCost * amount
	local withdrawSuccessful = false

	PlayerDataServer.updateValue(player, PlayerDataKey.Coins, function(numCurrencyMaybe: number?)
		local numCurrency = (numCurrencyMaybe or 0) - totalCost

		if numCurrency < 0 then
			return nil
		end

		withdrawSuccessful = true
		return numCurrency
	end)

	if not withdrawSuccessful then
		return false, ItemPurchaseFailureReason.InsufficientFunds
	end

	PlayerDataServer.updateValue(player, PlayerDataKey.Inventory, function(
		inventory: {
			[string]: { -- [category]: countByItemId
				[string]: number, -- [itemId]: count
			},
		}
	)
		local itemCountById: { [string]: number } = inventory[itemCategory] or {}
		local itemCount = itemCountById[itemId] or 0
		itemCount += amount

		itemCountById[itemId] = itemCount
		inventory[itemCategory] = itemCountById

		return inventory
	end)

	local endingBalance = PlayerDataServer.getValue(player, PlayerDataKey.Coins)
	EconomyAnalytics.logItemPurchased(player, itemId, itemCategory, endingBalance, totalCost)

	Market.itemsPurchased:Fire(player, itemId, itemCategory, amount)

	return true
end

return Market
