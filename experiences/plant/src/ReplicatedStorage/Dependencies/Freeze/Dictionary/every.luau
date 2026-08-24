--!strict
local everyImpl = require(script.Parent.Parent.utils.every)
--[=[
	Returns true if `predicate` returns true for all entries in the Dictionary.

	```lua
	Dictionary.every({ a = 1, b = 2, c = 3 }, function(value, key)
		return value < 10
	end)
	-- true
	```

	@within Dictionary
]=]

local function every<Key, Value>(list: { [Key]: Value }, predicate: (Value, Key) -> boolean): boolean
	return everyImpl(list, predicate)
end

return every
