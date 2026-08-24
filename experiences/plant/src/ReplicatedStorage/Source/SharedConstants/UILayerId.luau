--!strict

--[[
	Pseudo enums used to give unique names to UILayers so they can
	be referenced by name rather than typo-prone strings.
--]]

export type EnumType =
	"SeedMarket"
	| "PlantSeed"
	| "GardenStore"
	| "PlacePot"
	| "DataErrorNotice"
	| "BuyCoins"
	| "CoinIndicator"
	| "Inventory"
	| "InventoryButton"
	| "ResetDataButton"

local UILayerId = {
	SeedMarket = "SeedMarket" :: "SeedMarket",
	PlantSeed = "PlantSeed" :: "PlantSeed",
	GardenStore = "GardenStore" :: "GardenStore",
	PlacePot = "PlacePot" :: "PlacePot",
	DataErrorNotice = "DataErrorNotice" :: "DataErrorNotice",
	BuyCoins = "BuyCoins" :: "BuyCoins",
	CoinIndicator = "CoinIndicator" :: "CoinIndicator",
	Inventory = "Inventory" :: "Inventory",
	InventoryButton = "InventoryButton" :: "InventoryButton",
	ResetDataButton = "ResetDataButton" :: "ResetDataButton",
}

return UILayerId
