--[[
	CollectionService tags to identify characters and state about the character
--]]

export type EnumType = "Character" | "Holding" | "PullingWagon"

local CharacterTag = {
	Character = "Character" :: "Character",
	Holding = "Holding" :: "Holding",
	PullingWagon = "PullingWagon" :: "PullingWagon",
}

return CharacterTag
