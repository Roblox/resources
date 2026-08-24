--[[
	CollectionService tag used to identify objects to avoid welding to the PrimaryPart
	during model setup, such as avoiding welding the dynamic farm door since it
	is connected separately with a HingeConstraint and needs to be free to move.
--]]

export type EnumType = "DoNotWeld"

local DoNotWeldTag = "DoNotWeld" :: "DoNotWeld"

return DoNotWeldTag
