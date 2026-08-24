--!strict

--[[
	A type used by scripts that accept any CollectionService tag. This type contains a
	list of all CollectionService tags used by scripts. This type must be kept up to date
	with all other EnumTypes alongside this file in the CollectionServiceTag folder.

	This is not ideal because changing tags requires changing more than one file, but it's
	a necessary downside in order to have more strict custom enum typing in Luau's state at the time of writing.
--]]

export type EnumType =
	"Player"
	| "DoNotWeld"
	| "VisibleWhenVendorEnabled"
	| "AnimatedRoosterNPC"
	| "AnimatedShopSymbol"
	| "CanPlaceTable"
	| "CanPlacePot"
	| "NeedsWater"
	| "Growing"
	| "CanHarvest"
	| "CanPlant"
	| "CanRemove"
	| "Character"
	| "Holding"
	| "PullingWagon"
	| "CanPlace"
	| "WagonFull"
	| "WagonEmpty"
	| "Wagon"
	| "ZonePart"
	| "InFarm"
	| "InMarket"
	| "InShop"
	| "InGardenStore"

return nil
