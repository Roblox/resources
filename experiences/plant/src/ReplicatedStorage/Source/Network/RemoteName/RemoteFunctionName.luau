--!strict

--[[
	Specifies the names of all RemoteFunctions. One RemoteFunction object gets generated for each name
	in this list, and these names are used as enums when interacting with Network to tell it
	which remote function to fire without typing out typo-prone string literals.
--]]

export type EnumType = "RequestItemPurchase"

local RemoteFunctionName = {
	RequestItemPurchase = "RequestItemPurchase" :: "RequestItemPurchase",
}

return RemoteFunctionName
