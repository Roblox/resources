--!strict

--[[
	Creates instances with given properties based on the given tree data table.
	This streamlines the tedious process of calling Instance.new and setting each property
	by creating a table of properties and a ClassName instead.
--]]

type PropertiesTable = { [string]: any }

type InstanceTree = {
	className: string,
	properties: PropertiesTable?,
	children: { InstanceTree }?,
}

local function createInstanceTree(tree: InstanceTree)
	local object = Instance.new(tree.className)

	if tree.properties then
		for property, value in pairs(tree.properties :: PropertiesTable) do
			assert(property ~= "Parent", "Cannot set Parent as property through createInstanceTree")
			object[property] = value
		end
	end

	if tree.children then
		for _, childTree in ipairs(tree.children :: { InstanceTree }) do
			local childObject = createInstanceTree(childTree)
			childObject.Parent = object
		end
	end

	return object
end

return createInstanceTree
