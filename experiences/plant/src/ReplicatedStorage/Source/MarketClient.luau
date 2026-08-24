--!strict

--[[
	Provides a client-side API to interact with the server market, including pcalling the network
	request and wrapping the pcall result and server result together into one result.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local ItemPurchaseFailureReason =
	require(ReplicatedStorage.Source.SharedConstants.RequestFailureReason.ItemPurchaseFailureReason)

local MarketClient = {}

function MarketClient.requestItemPurchaseAsync(itemId: string, itemCategory: ItemCategory.EnumType, amount: number)
	-- invokeServerAsync wraps the request in a pcall, so we receive two success and result pairs:
	-- one from the pcall and one from the server's purchase request handler
	local networkRequestSuccess: boolean -- Result of the pcall wrapping the network request
	local networkRequestResult: string | boolean -- pcall network request failure reason, or purchase success result from the server
	local purchaseFailureReason: ItemPurchaseFailureReason.EnumType? -- Purchase rejection/failure reason from the server

	networkRequestSuccess, networkRequestResult, purchaseFailureReason =
		Network.invokeServerAsync(Network.RemoteFunctions.RequestItemPurchase, itemId, itemCategory, amount)

	-- Aggregate the network pcall success results with the purchase success results
	local overallSuccess = networkRequestSuccess and networkRequestResult :: boolean
	local eitherFailureReason = if networkRequestSuccess
		then purchaseFailureReason
		else tostring(networkRequestResult) :: string?

	return overallSuccess, eitherFailureReason
end

-- TODO: Consider moving wagon sell requests to this module

return MarketClient
