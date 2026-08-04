--!strict

--[[
	Searches children of an instance, returning the first child containing an attribute
	matching the given name and value.
--]]

local function findFirstChildWithAttribute(parent: Instance, attributeName: string, attributeValue: any): Instance?
	local children = parent:GetChildren()

	for _, child in pairs(children) do
		if child:GetAttribute(attributeName) == attributeValue then
			return child
		end
	end

	return nil
end

return findFirstChildWithAttribute
