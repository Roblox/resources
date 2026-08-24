--!strict
local filter = require(script.Parent.filter)

--[=[
	Returns a Dictionary of only entries for which the `predicate` function returns false.

	```lua
	Dictionary.filterNot({ a = 1, b = 2, c = 3, d = 4 }, function(value, key)
		return value % 2 == 0
	end)
	-- { a = 1, c = 3 }
	```

	@within Dictionary
]=]

local function filterNot<Key, Value>(dictionary: { [Key]: Value }, predicate: (Value, Key) -> boolean): { [Key]: Value }
	return filter(dictionary, function(value, key)
		return not predicate(value, key)
	end)
end

return filterNot
