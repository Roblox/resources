--!strict

--[[
	A mapping of ItemCategory to their container so that item lookups can
	be performed by item category and itemId
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCategory = require(script.Parent.ItemCategory)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local ContainerByCategory: { [string]: Folder } = {
	[ItemCategory.Plants] = getInstance(ReplicatedStorage, "Instances", "Plants"),
	[ItemCategory.Pots] = getInstance(ReplicatedStorage, "Instances", "Pots"),
	[ItemCategory.Seeds] = getInstance(ReplicatedStorage, "Instances", "Seeds"),
	[ItemCategory.Wagons] = getInstance(ReplicatedStorage, "Instances", "Wagons"),
	[ItemCategory.Tables] = getInstance(ReplicatedStorage, "Instances", "Tables"),
	[ItemCategory.CoinBundles] = getInstance(ReplicatedStorage, "Instances", "CoinBundles"),
}

return ContainerByCategory
