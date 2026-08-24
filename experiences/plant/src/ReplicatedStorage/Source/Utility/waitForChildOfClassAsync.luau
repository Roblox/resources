--!strict

--[[
	Waits for a child to be added with the specified class, or returns one
	if it exists already.
--]]

local function waitForChildOfClassAsync(instance: Instance, className: string)
	local child = instance:FindFirstChildOfClass(className)

	while not child do
		instance.ChildAdded:Wait()
		child = instance:FindFirstChildOfClass(className)
	end

	return child
end

return waitForChildOfClassAsync
