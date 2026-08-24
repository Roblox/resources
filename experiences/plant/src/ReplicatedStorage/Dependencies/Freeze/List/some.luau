--!strict
local someImpl = require(script.Parent.Parent.utils.some)
--[=[
	Returns true if `predicate` returns true for any entry in the List.

	```lua
	List.some({ 1, 2, 3 }, function(value, index)
		return value % 2 == 0
	end)
	-- true
	```

	@within List
]=]

local function some<Value>(list: { Value }, predicate: (Value, number) -> boolean): boolean
	return someImpl(list, predicate)
end

return some
