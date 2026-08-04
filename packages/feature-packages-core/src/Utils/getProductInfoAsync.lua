--!strict

--[[
	Utility for fetching product information from MarketplaceService asynchronously with retry.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local retryAsync = require(ReplicatedStorage.FeaturePackagesCore.Utils.retryAsync)

local MAX_ATTEMPTS = 4
local RETRY_PAUSE_CONSTANT = 2
local RETRY_PAUSE_EXPONENT = 2

local function getProductInfoAsync(productId: number, productType: Enum.InfoType): { [string]: any }?
	local success, productInfo = retryAsync(function()
		return MarketplaceService:GetProductInfo(productId, productType)
	end, MAX_ATTEMPTS, RETRY_PAUSE_CONSTANT, RETRY_PAUSE_EXPONENT)

	if success then
		return productInfo
	end

	warn("Failed to fetch product info for productId: " .. productId)
	return nil
end

return getProductInfoAsync
