--!strict

--[[
	Pseudo enums used as reasons for failure to compare by name rather than comparing
	typo-prone strings.
--]]

export type EnumType = "InvalidItemCategory" | "InvalidItemId" | "InsufficientFunds"

local ItemPurchaseFailureReason = {
	InvalidItemCategory = "InvalidItemCategory" :: "InvalidItemCategory",
	InvalidItemId = "InvalidItemId" :: "InvalidItemId",
	InsufficientFunds = "InsufficientFunds" :: "InsufficientFunds",
}

return ItemPurchaseFailureReason
