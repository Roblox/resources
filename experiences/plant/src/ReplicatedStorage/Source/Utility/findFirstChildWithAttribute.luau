--!strict

--[[
	Searches children of an instance, returning the first child containing an attribute
	matching the given name and value.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)

local function findFirstChildWithAttribute(
	parent: Instance,
	attributeName: Attribute.EnumType,
	attributeValue: any
): Instance?
	local children = parent:GetChildren()
	local child = Freeze.List.find(children, function(instance: Instance, index: number)
		return instance:GetAttribute(attributeName) == attributeValue
	end, nil)

	return child
end

return findFirstChildWithAttribute
