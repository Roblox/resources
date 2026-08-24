--!strict

--[[
	Waits for a child to be added with the specified attribute, or returns one
	if it exists already.

	This does not track changes in attributes of children, so the attribute must be present
	when this function is called or when the child is added.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local findFirstChildWithAttribute = require(ReplicatedStorage.Source.Utility.findFirstChildWithAttribute)

local function waitForChildWithAttributeAsync(parent: Instance, attributeName: Attribute.EnumType, attributeValue: any)
	local childWithAttribute = findFirstChildWithAttribute(parent, attributeName, attributeValue)

	while not childWithAttribute do
		parent.ChildAdded:Wait()
		childWithAttribute = findFirstChildWithAttribute(parent, attributeName, attributeValue)
	end

	return childWithAttribute :: Instance
end

return waitForChildWithAttributeAsync
