--!strict
local push = require(script.Parent.Parent.push)
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within List
	@deprecated v0.0.4 -- Use [List.push] instead.
]=]

local function append<Value>(list: { Value }, ...: Value): { Value }
	deprecationWarning("List." .. script.Name, "List.push")
	return push(list, ...)
end

return append
