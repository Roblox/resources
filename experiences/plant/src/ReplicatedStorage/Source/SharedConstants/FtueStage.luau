--!strict

--[[
	Stages for a player's First Time User Experience (FTUE), used in the player's data to keep track of
	FTUE state and elsewhere to show appropriate prompts and customize the world according to the stage
--]]

export type EnumType = "InFarm" | "SellingPlant" | "PurchasingSeed" | "PurchasingPot" | "ReturningToFarm" | "Complete"

local FtueStage = {
	InFarm = "InFarm" :: "InFarm",
	SellingPlant = "SellingPlant" :: "SellingPlant",
	PurchasingSeed = "PurchasingSeed" :: "PurchasingSeed",
	PurchasingPot = "PurchasingPot" :: "PurchasingPot",
	ReturningToFarm = "ReturningToFarm" :: "ReturningToFarm",
	Complete = "Complete" :: "Complete",
}

return FtueStage
