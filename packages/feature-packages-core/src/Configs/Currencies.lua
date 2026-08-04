--!strict

--[[
	A source of truth list of all in-experience currencies known by FeaturePackages.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyTypes = require(ReplicatedStorage.FeaturePackagesCore.Configs.CurrencyTypes)

-- Replace this with your own currencies, if your experience has any.
local Currencies: CurrencyTypes.CurrencyList = {
	-- An example currency
	-- Gems = {
	-- 	displayName = "Gems",
	-- 	symbol = "💎",
	-- 	icon = nil,
	-- },
}

return Currencies
