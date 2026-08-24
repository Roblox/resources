--!strict

--[[
	A table of strings to be used by client or server scripts. These are centralized
	in one place for easier tracking of what dynamic strings are in the game, which is useful
	for assembling a list of strings to translate. It also mitigates repeated string constant definition
	in multiple files.
--]]

local PlayerFacingString = {
	ImageAsset = {
		Prefix = "rbxassetid://", -- Scripts append an image asset ID for the Image property of guis
		None = "", -- Empty strings in a gui's Image property makes the image invisible
	},
	ValueManager = { -- Unique strings used as keys for ValueManager offsets and multipliers
		Sprint = "sprint",
		ViewingMenu = "viewingMenu",
		PullingWagon = "pullingWagon",
	},
	Formats = { -- Passed to string.format() with values substituting the placeholders
		CoinBundleShop = {
			BundleName = "%d", -- Uses CoinBundleSize attribute
			ListItemCost = " %d", -- Uses robux cost ( is Robux unicode symbol)
			ActionButtonText = "Buy (%d)", -- Uses robux cost ( is Robux unicode symbol)
		},
		Shop = {
			ActionButtonText = "Buy %d", -- Uses in-game currency cost
			ListItemCost = "%d", -- Uses in-game currency cost
			BuyMoreCurrency = "Buy", -- Gets followed by an image of the currency coin, not formatted
		},
		ItemPlacement = {
			PlantActionButtonText = "PLANT %s", -- Uses item DisplayName attribute
			PlaceActionButtonText = "PLACE %s", -- Uses item DisplayName attribute
			NeedsLargerPot = "NEEDS LARGER POT", -- Not formatted
		},
	},
	ResetDataButton = {
		Confirm = "Confirm?", -- Shows on the first button press, requiring a second because it's a dangerous action
		ConfirmSubText = "Wipes your progress. No undo", -- Clarification while the Confirm message is showing
	},
	CallToAction = { -- Action text on ProximityPrompt CTAs
		HarvestPlant = "Harvest plant",
		PlacePlant = "Place plant",
		PlacePot = "Place pot",
		PlaceTable = "Place table",
		PlantSeed = "Plant seed",
		WaterPlant = "Water plant",
		RemovePot = "Remove pot",
	},
	ListSelector = {
		GardenStore = {
			Title = "Buy Garden Supplies",
			FooterDescription = "Owned",
		},
		SeedMarket = {
			Title = "Buy Seeds",
			FooterDescription = "Owned",
		},
		Inventory = {
			Title = "Inventory",
			FooterDescription = "Owned",
		},
		PlantSeed = {
			Title = "Plant Seed",
			FooterDescription = "Owned",
		},
		PlacePot = {
			Title = "Place Pot",
			FooterDescription = "Owned",
		},
		BuyCoins = {
			Title = "Buy",
			FooterDescription = "",
		},
	},
}

return PlayerFacingString
