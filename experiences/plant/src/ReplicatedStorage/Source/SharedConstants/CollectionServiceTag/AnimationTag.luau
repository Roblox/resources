--[[
	CollectionService tags used by animation scripts to identify objects
	in the world to animate
--]]

export type EnumType = "AnimatedRoosterNPC" | "AnimatedShopSymbol"

local AnimationTag = {
	AnimatedRoosterNPC = "AnimatedRoosterNPC" :: "AnimatedRoosterNPC",
	AnimatedShopSymbol = "AnimatedShopSymbol" :: "AnimatedShopSymbol",
}

return AnimationTag
