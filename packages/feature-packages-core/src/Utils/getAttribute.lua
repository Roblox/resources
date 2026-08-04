--!strict

--[[
	Returns the value of an attribute on an instance, erroring if the
	attribute doesn't exist. Normally, calling :GetAttribute() doesn't error,
	but in most cases, getting an attribute should only happen where it's guaranteed
	to exist, and we therefore want it to error.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attributes = require(ReplicatedStorage.FeaturePackagesCore.Configs.Attributes)

local function getAttribute<T>(instance: Instance, attributeName: Attributes.EnumType): T
	local value = instance:GetAttribute(attributeName)
	assert(value ~= nil, ("%s is not a valid attribute of %s"):format(attributeName, instance:GetFullName()))

	return value
end

return getAttribute
