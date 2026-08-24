--!strict
local findPair = require(script.Parent.Parent.utils.findPair)

--[=[
	Returns the first index for which the `predicate` returns true.

	```lua
	List.findIndex({ "a", "B", "c" }, function(value, index)
		return value == string.upper(v)
	end)
	-- 2
	```

	@within List
]=]

local function findIndex<Value>(list: { Value }, predicate: (Value, number) -> boolean): number?
	local index, _ = findPair(list, predicate)
	return index
end

return findIndex
