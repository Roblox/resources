--!strict
local findPairImpl = require(script.Parent.Parent.utils.findPair)

--[=[
	Returns the first [index, value] pair for which the `predicate` returns true.

	```lua
	List.findPair({ "a", "B", "c" }, function(value, index)
		return value == string.upper(v)
	end)
	-- ( 2, "B" )
	```

	@within List
]=]

local function findPair<Value>(list: { Value }, predicate: (Value, number) -> boolean): (number?, Value?)
	return findPairImpl(list, predicate)
end

return findPair
