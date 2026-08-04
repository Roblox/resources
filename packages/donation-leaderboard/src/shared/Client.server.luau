--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local donationProducts = require(script.Parent.DonationProducts)
local instances = script.Parent:WaitForChild("Instances")

local player = Players.LocalPlayer :: Player
local playerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
local leaderboard = script.Parent:WaitForChild("Leaderboard")
local leaderboardGui = leaderboard:WaitForChild("Display"):WaitForChild("LeaderboardGui")

local ROBUX_TEMPLATE = utf8.char(0xE002) .. " %d" -- char code 0xE002 is reserved for the Robux icon
local ASSET_TEMPLATE = "rbxassetid://%d"

-- Add a button to prompt the pruchase of a DevProduct used for donations
local function addProduct(productId)
	local success, productInfo = pcall(function()
		return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
	end)
	if not success then
		warn(`Failed to get info for product {productId}`)
		return
	end

	local icon = productInfo.IconImageAssetId
	local price = productInfo.PriceInRobux

	local button = instances.ProductButton:Clone()
	button.LayoutOrder = price
	button.ImageLabel.Image = ASSET_TEMPLATE:format(icon)
	button.RobuxLabel.Text = ROBUX_TEMPLATE:format(price)
	button.Parent = leaderboardGui.ProductList :: any

	button.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
end

local function initialize()
	-- Parent the leaderboard GUI to playerGui so that buttons inside it can be interacted with
	local adornee = leaderboardGui.Parent
	leaderboardGui.Parent = playerGui :: any
	leaderboardGui.Adornee = adornee

	for _, productId in donationProducts do
		addProduct(productId)
	end
end

initialize()
