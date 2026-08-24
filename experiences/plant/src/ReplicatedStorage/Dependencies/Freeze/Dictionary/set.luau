--!strict
local setImpl = require(script.Parent.Parent.utils.set)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a Dictionary which includes `value` at `key`.
	If `key` already exists, it will be replaced.

	```lua
	Dictionary.set({ a = 10, b = 20, c = 30 }, "a", 100)
	-- { a = 100, b = 20, c = 30 }
	```

	@within Dictionary
]=]

local function set<Key, Value>(dictionary: { [Key]: Value }, key: Key, value: Value): { [Key]: Value }
	if key == nil then
		return dictionary
	end

	return maybeFreeze(setImpl(dictionary, key, value))
end

return set
