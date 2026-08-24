--[[
	CollectionService tags indicating state of placement areas,
	used by CallToAction logic to determine when to show the CTA
--]]

export type EnumType = "CanPlaceTable" | "CanPlacePot"

local PlacementTag = {
	CanPlaceTable = "CanPlaceTable" :: "CanPlaceTable",
	CanPlacePot = "CanPlacePot" :: "CanPlacePot",
}

return PlacementTag
