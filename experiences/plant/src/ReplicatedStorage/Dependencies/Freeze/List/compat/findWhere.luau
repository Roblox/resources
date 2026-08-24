--!strict
local find = require(script.Parent.Parent.find)
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within List
	@deprecated v0.0.4 -- Use [List.find] instead.
]=]

local function findWhere<Value>(list: { Value }, predicate: (Value, number) -> boolean, from: never): Value?
	assert(from == nil, "[Freeze] findWhere's `from` argument is not supported.")
	deprecationWarning("List." .. script.Name, "List.find")
	return find(list, predicate)
end

return findWhere
