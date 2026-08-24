--!strict
local mapImpl = require(script.Parent.Parent.utils.map)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a new Dictionary with keys and values passed through a `mapper` function.

	Returning a second value in the mapper function will reassign the key.

	```lua
	Dictionary.map({ a = 1, b = 2, c = 3 }, function(value, key)
		return value * 10, key
	end)
	-- { a = 10, b = 20, c = 30 }
	```

	@within Dictionary
]=]

local function map<Key, Value, NewKey, NewValue>(dictionary: { [Key]: Value }, mapper: (Value, Key) -> (NewValue, NewKey)): { [NewKey]: NewValue? }
	return maybeFreeze(mapImpl(dictionary, mapper))
end

return map
