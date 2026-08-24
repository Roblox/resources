--!strict

--[[
	A class that downloads and stores the price of every Developer Product in the game
	Useful for when this information is later required in a situation where making a yielding
	web request is not appropriate.
--]]

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local iterateOverPagesAsync = require(ReplicatedStorage.Source.Utility.iterateOverPagesAsync)
local retryAsync = require(ReplicatedStorage.Source.Utility.retryAsync)

local MAX_RETRIES = 3
local RETRY_CONSTANT = 5
local RETRY_EXPONENT = 5

local DevProductPriceList = {}
DevProductPriceList._prices = {} :: { [number]: number }
DevProductPriceList._setupSucceeded = nil :: boolean?

function DevProductPriceList.setupAsync()
	local success, result = retryAsync(function()
		-- If the PlaceId is zero, the game is not published. This means GetDeveloperProductsAsync() will throw.
		if game.PlaceId == 0 then
			return
		end

		local developerProducts = MarketplaceService:GetDeveloperProductsAsync() :: Pages

		for developerProductInfo in iterateOverPagesAsync(developerProducts) do
			DevProductPriceList._prices[developerProductInfo.ProductId] = developerProductInfo.PriceInRobux
		end
	end, MAX_RETRIES, RETRY_CONSTANT, RETRY_EXPONENT)

	DevProductPriceList._setupSucceeded = success

	if not success then
		warn("Failed to load developer product info: " .. result)
	end
end

function DevProductPriceList.get(developerProductId: number)
	assert(
		DevProductPriceList._setupSucceeded ~= nil,
		"Cannot lookup developer product price until DevProductPriceList.:setupAsync has been called"
	)

	local productPrice = DevProductPriceList._prices[developerProductId]
	if productPrice then
		return productPrice
	else
		warn(
			string.format(
				"Failed to load developer product price for product Id: %d. Does this Developer Product belong to this experience?",
				developerProductId
			)
		)

		return 0
	end
end

return DevProductPriceList
