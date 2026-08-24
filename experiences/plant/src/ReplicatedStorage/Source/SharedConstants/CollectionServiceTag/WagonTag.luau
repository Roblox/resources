--[[
	CollectionService tags to identify wagons and state about the wagon,
	used by CallToAction logic to determine UI visibility
--]]

export type EnumType = "CanPlace" | "WagonFull" | "WagonEmpty" | "Wagon"

local WagonTag = {
	CanPlace = "CanPlace" :: "CanPlace",
	WagonFull = "WagonFull" :: "WagonFull",
	WagonEmpty = "WagonEmpty" :: "WagonEmpty",
	Wagon = "Wagon" :: "Wagon",
}

return WagonTag
