--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a list of values. Order is undefined.

	```lua
	Dictionary.values({ a = 1, b = 2, c = 3 })
	-- { 1, 2, 3 }
	```

	@within Dictionary
]=]

local function values<Key, Value>(dictionary: { [Key]: Value }): { Value }
	local new = {}

	for _, value in dictionary do
		table.insert(new, value)
	end

	return maybeFreeze(new)
end

return values
