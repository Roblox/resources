--!strict

--[[
	Returns the instance corresponding with the given path of object names. Errors if this instance does not exist.

	Useful for accessing Instance trees generated at runtime in strict mode. For example:

	local mast: Model = getInstance(rootInstance, "Ship", "Mast")
--]]

local function getInstance<T>(instance: Instance, ...: string): T
	for _, childName in ipairs({ ... }) do
		local child = instance:FindFirstChild(childName)
		assert(child, string.format("%s is not a child of %s", childName, instance:GetFullName()))
		instance = child
	end

	-- We want this function to be callable with generic types
	return (instance :: any) :: T
end

return getInstance
