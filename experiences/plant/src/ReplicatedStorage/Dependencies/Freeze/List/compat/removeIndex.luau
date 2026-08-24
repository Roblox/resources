--!strict
local remove = require(script.Parent.Parent:FindFirstChild("remove"))
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within List
	@deprecated v0.0.4 -- Use [List.remove] instead.
]=]

local function removeIndex<Value>(list: { Value }, index: number): { Value }
	deprecationWarning("List." .. script.Name, "List.remove")
	return remove(list, index)
end

return removeIndex
