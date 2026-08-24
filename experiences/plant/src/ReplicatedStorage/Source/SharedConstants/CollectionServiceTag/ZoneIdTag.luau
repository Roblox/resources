--[[
	A source of truth list of all CollectionService tags allowed in attributes of parts tagged with ZonePart.
	These tags are used to tag instances inside the Zone.
--]]

export type EnumType = "InFarm" | "InMarket" | "InShop" | "InGardenStore"

local ZoneIdTag = {
	InFarm = "InFarm" :: "InFarm",
	InMarket = "InMarket" :: "InMarket",
	InShop = "InShop" :: "InShop",
	InGardenStore = "InGardenStore" :: "InGardenStore",
}

return ZoneIdTag
