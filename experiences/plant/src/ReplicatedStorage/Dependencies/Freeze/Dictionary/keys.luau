--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a list of keys. Order is undefined.

	```lua
	Dictionary.keys({ a = 1, b = 2, c = 3 })
	-- { "a", "b", "c" }
	```

	@within Dictionary
]=]

local function keys<Key, Value>(dictionary: { [Key]: Value }): { Key }
	local new = {}

	for key, _ in dictionary do
		table.insert(new, key)
	end

	return maybeFreeze(new)
end

return keys
