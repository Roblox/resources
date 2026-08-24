--!strict

--[[
	Pseudo enums to specify order of operations, used by ValueManager for number multipliers and offsets.
--]]

export type EnumType = "MultiplyThenOffset" | "OffsetThenMultiply"

local OperationOrder = {
	MultiplyThenOffset = "MultiplyThenOffset" :: "MultiplyThenOffset",
	OffsetThenMultiply = "OffsetThenMultiply" :: "OffsetThenMultiply",
}

return OperationOrder
