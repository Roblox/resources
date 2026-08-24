--!strict
local findPair = require(script.Parent.Parent.utils.findPair)

--[=[
	Returns the first value for which the `predicate` returns true.

	```lua
	List.find({ "a", "B", "c" }, function(value, key)
		return value == string.upper(v)
	end)
	-- "B"
	```

	@within List
]=]

local function find<Value>(list: { Value }, predicate: (Value, number) -> boolean, notSetValue: Value?): Value?
	local _, value = findPair(list, predicate)
	return if value == nil then notSetValue else value
end

return find
