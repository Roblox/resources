--!strict

--[[
	The ReceiptProcessor handles processing developer product purchases. Following these principles:

	1. All purchases have a DataStore representation
	2. A purchase should not be finalized until it has been saved in a DataStore

	This file seeks to address the common pitfalls in ProcessReceipt implementations, including:

	1. Returning PurchaseGranted before the purchase has been recorded in the player's DataStore
	2. Checking and recording the PurchaseId in separate non-atomic GetAsync / SetAsync calls
	3. Implementing complex transaction systems to atomically update the session and DataStore data
	4. Recording a purchase as failed if the initial attempt to save it fails, even if a later attempt succeeds
--]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local PlayerDataServer = require(script.Parent.PlayerData.Server)
local waitForFirstAsync = require(script.waitForFirstAsync)

local MAX_RECEIPT_HISTORY = 100 -- The maximum number of receipts to store in the player data
local RECEIPT_HISTORY_VALUE_NAME = "__receiptHistory" -- The name of the value in the player data that stores receipt history

type ProductCallback = (Player, number) -> nil

type ReceiptInfo = {
	PurchaseId: string, -- A unique identifier for the specific purchase
	PlayerId: number, -- The ID of the player who made the purchase
	ProductId: number, -- The ID of the purchased product
	CurrencySpent: number, -- The amount of currency spent in the purchase
	CurrencyType: Enum.CurrencyType, -- The type of currency spent in the purchase; always Enum.CurrencyType.Robux
	PlaceIdWherePurchased: number, -- The ID of the place where the product was purchased (not necessarily the same as the current place's ID)
}

local ReceiptProcessor = {}
ReceiptProcessor._productCallbacks = {} :: { [number]: ProductCallback }
-- We expose this constant as a property of ReceiptProcessor so the PlayerData system can set it as a
-- private value that is not replicated to the client
ReceiptProcessor.receiptHistoryValueName = RECEIPT_HISTORY_VALUE_NAME

function ReceiptProcessor.start()
	MarketplaceService.ProcessReceipt = function(receiptInfo: ReceiptInfo)
		local playerId = receiptInfo.PlayerId
		local productId = receiptInfo.ProductId
		local purchaseId = receiptInfo.PurchaseId

		local result = ReceiptProcessor._processReceiptAsync(playerId, productId, purchaseId)

		return result
	end
end

-- The product callback is the function that manipulates the session data to process the purchase
-- Example:
-- ReceiptProcessor.registerProductCallback(12345, function(player)
-- 	PlayerDataServer.updateValue(player, "coins", function(oldValue)
-- 		return oldValue + 1
-- 	end)
-- end)
function ReceiptProcessor.registerProductCallback(developerProductId: number, productCallback: ProductCallback)
	assert(
		not ReceiptProcessor._productCallbacks[developerProductId],
		string.format("Developer product %d already has a callback assigned", developerProductId)
	)
	ReceiptProcessor._productCallbacks[developerProductId] = productCallback
end

function ReceiptProcessor._processReceiptAsync(
	playerId: number,
	productId: number,
	purchaseId: string
): Enum.ProductPurchaseDecision
	-- We do not want to save player data if the player is not currently in the server
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Because ProcessReceipt can be invoked when the player joins the server, we want to make sure that we've
	-- given the player's data time to load before continuing
	if PlayerDataServer.isLoading(player) then
		-- Here, we are waiting for the player's data to load OR for the player to leave the server (whichever happens first)
		-- We are including the player leaving the server here as if we instead yielded indefinitely when the player left the server
		-- prior to their data load, ProcessReceipt would be blocked from being invoked again on this server for this purchase
		-- even if the player rejoined.
		waitForFirstAsync(function()
			PlayerDataServer.waitForDataLoadAsync(player)
		end, function()
			-- TODO: Replace with player.Destroying:Wait() when that fires on player leave
			local _, playerParent
			repeat
				_, playerParent = player.AncestryChanged:Wait()
			until playerParent == nil
		end)
	end

	-- We do not want to save player data if it is currently loading, has errored or saving is otherwise disabled
	-- This check will also capture if the player has left without their data loading
	if not PlayerDataServer.canSave(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Because the PlayerData system uses session locking, we can guarantee that the player data in memory
	-- on the server by PlayerDataServer is the most up to date version available. Therefore, we do not
	-- need to check to see if a more recent Data Store value exists where the receipt is handled.
	local receiptsProcessed = PlayerDataServer.getValue(player, ReceiptProcessor.receiptHistoryValueName) or {}
	if table.find(receiptsProcessed, purchaseId) then
		-- We are passing in the syncedValueOnly parameter, so we will only get a value that has been
		-- successfully loaded or saved to the DataStore.
		local receiptsProcessedSynced = PlayerDataServer.getValue(
			player,
			ReceiptProcessor.receiptHistoryValueName,
			true
		) or {}

		if not table.find(receiptsProcessedSynced, purchaseId) then
			-- The current session data shows the purchase has been handled in this session, but this has not been reflected in
			-- the DataStore. This suggests that PlayerDataServer.saveDataAsync failed to save on a previous ProcessReceipt callback
			-- for this purchase. In this case, we will return NotProcessedYet. The next time this callback runs, if the data has
			-- since saved successfully it will return PurchaseGranted.

			-- Although we _could_ prompt another save here, we are opting not to as it will be more efficient to allow
			-- the player data to be saved in the subsequent PlayerData auto save / save triggered when the player leaves

			warn("PurchaseId found in session ReceiptHistory but not player ReceiptHistory.")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- As the purchaseId is already stored in our session data, and reflected in the Datastore, we know the purchase has
		-- been handled in this or a previous session. It's important we return PurchaseGranted here to capture cases where the
		-- purchase has finished processing, but ProcessReceipt failed to be recorded in the backend service.
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- If no product callback has been set, we are unable to process this purchase
	local productCallback = ReceiptProcessor._productCallbacks[productId]
	if not productCallback then
		warn(string.format("Product %d has no callback set", productId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- The purchase is processed in the user's session data inside the product callback
	local productSuccess, productResult = pcall(productCallback, player, productId)

	-- If the product callback errored, we are unable to process the purchase
	if not productSuccess then
		warn("Error when calling product callback: " .. tostring(productResult))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- We need to store the receiptId in the player data history so we do not award this purchase twice
	PlayerDataServer.updateValue(player, ReceiptProcessor.receiptHistoryValueName, function(receipts: { string })
		receipts = receipts or {}
		table.insert(receipts, purchaseId)

		if #receipts > MAX_RECEIPT_HISTORY then
			table.remove(receipts, 1) -- trim the beginning of the list
		end

		return receipts
	end)

	local saveSuccess, saveResult = PlayerDataServer.saveDataAsync(player)

	-- We only want to record this purchase as processed if it has been successfully saved to the DataStore
	-- If the save fails, we will record this purchase as NotProcessedYet
	if not saveSuccess then
		warn("Failed to save player data while processing receipt: " .. tostring(saveResult))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- We now know the purchase has been correctly handled in the current session, and the changes
	-- have been saved to the DataStore so we are free to mark this purchase as finalized
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

return ReceiptProcessor
