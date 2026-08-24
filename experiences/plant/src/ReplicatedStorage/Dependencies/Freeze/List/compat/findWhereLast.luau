--!strict
local reverse = require(script.Parent.Parent.reverse)
local find = require(script.Parent.Parent.find)
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within List
	@deprecated v0.0.4 -- Use [List.reverse] and then [List.find] instead.
]=]

local function findWhereLast<Value>(list: { Value }, predicate: (Value, number) -> boolean, from: never?): Value?
	assert(from == nil, "[Freeze] findWhereLast's `from` argument is not supported.")
	deprecationWarning("List." .. script.Name, "List.reverse and then List.find")
	local reveresedList = reverse(list)
	return find(reveresedList, predicate)
end

return findWhereLast
