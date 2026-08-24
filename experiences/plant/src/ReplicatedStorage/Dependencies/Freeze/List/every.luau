--!strict
local everyImpl = require(script.Parent.Parent.utils.every)
--[=[
	Returns true if `predicate` returns true for all entries in the list.

	```lua
	List.every({ "a", "b", "c" }, function(value, key)
		return string.lower(value) == value
	end)
	-- true
	```

	@within List
]=]
local function every<Value>(list: { Value }, predicate: (Value, number) -> boolean): boolean
	return everyImpl(list, predicate)
end

return every
