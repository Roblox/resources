--!strict
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within List
	@deprecated v0.0.4 -- Use [table.create] instead.
]=]

local function create<Value>(count: number, value: Value?): { Value }
	deprecationWarning("List." .. script.Name, "table.create")
	return table.create(count, value)
end

return create
