--!strict

--[[
	Categories of items used to know where to find an item prefab when
	looking it up by item ID
--]]

export type EnumType = "Plants" | "Pots" | "Seeds" | "Tables" | "Wagons" | "CoinBundles"

local ItemCategory = {
	Plants = "Plants" :: "Plants",
	Pots = "Pots" :: "Pots",
	Seeds = "Seeds" :: "Seeds",
	Tables = "Tables" :: "Tables",
	Wagons = "Wagons" :: "Wagons",
	CoinBundles = "CoinBundles" :: "CoinBundles",
}

return ItemCategory
