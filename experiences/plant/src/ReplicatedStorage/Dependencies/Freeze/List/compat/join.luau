--!strict
local merge = require(script.Parent.Parent.merge)
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within List
	@deprecated v0.0.4 -- Use [List.merge] instead.
]=]

local function join<Value>(...: { any }): { any }
	deprecationWarning("List." .. script.Name, "List.merge")
	return merge(...)
end

return join
