--!strict
local updateImpl = require(script.Parent.Parent.utils.update)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a dictionary with the entry at `key` updated to the result of `updater`.

	If the entry does not exist, `updater` will be given `notSetValue` or nil.

	```lua
	Dictionary.update({ a = 10, b = 20, c = 30 }, "a", function(value)
		return value * 100
	end)
	-- { a = 1000, b = 20, c = 30 }

	Dictionary.update({ a = 10, b = 20, c = 30 }, "d", function(value)
		return value * 100
	end, 1)
	-- { a = 10, b = 20, c = 30, d = 100 }
	```

	@within Dictionary
]=]

local function update<Key, Value>(
	dictionary: { [Key]: Value },
	key: Key,
	updater: (Value?) -> Value,
	notSetValue: Value?
): { [Key]: Value }
	return maybeFreeze(updateImpl(dictionary, key, updater, notSetValue))
end

return update
