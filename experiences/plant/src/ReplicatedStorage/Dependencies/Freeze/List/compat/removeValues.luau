--!strict
local removeValue = require(script.Parent.Parent.removeValue)
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within List
	@deprecated v0.0.4 -- Use [List.removeValue] instead.
]=]

local function removeValues<Value>(list: { Value }, ...: Value): { Value }
	deprecationWarning("List." .. script.Name, "List.removeValue")
	return removeValue(list, ...)
end

return removeValues
