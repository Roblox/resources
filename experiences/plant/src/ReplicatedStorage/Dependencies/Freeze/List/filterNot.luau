--!strict
local filter = require(script.Parent.filter)

--[=[
	Returns a new List of only entries for which the `predicate` function returns false.

	```lua
	List.filterNot({ 1, 2, 3, 4 }, function(value, index)
		return value % 2 == 0
	end)
	-- { 1, 3 }
	```

	@within List
]=]

local function filterNot<Value>(list: { Value }, predicate: (Value, number) -> boolean): { Value }
	return filter(list, function(value, index)
		return not predicate(value, index)
	end)
end

return filterNot
