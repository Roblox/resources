--!strict
local someImpl = require(script.Parent.Parent.utils.some)
--[=[
	Returns true if `predicate` returns true for any entry in the dictionary.

	```lua
	Dictionary.some({ a = 1, b = 2, c = 3 }), function(value, key)
		return value % 2 == 0
	end)
	-- true
	```

	@within Dictionary
]=]

local function some<Key, Value>(dictionary: { [Key]: Value }, predicate: (Value, Key) -> boolean): boolean
	return someImpl(dictionary, predicate)
end

return some
