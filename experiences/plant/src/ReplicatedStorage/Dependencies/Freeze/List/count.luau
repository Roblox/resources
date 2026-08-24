--!strict
local countImpl = require(script.Parent.Parent.utils.count)

--[=[
	Returns the number of entries that match the `predicate`.
	If the `predicate` is not given, all entries will be considered a match.

	```lua
	List.count({ "a", "b", "c" })
	-- 3

	List.count({ "a", "b", "c" }, function(value)
		return value == "b"
	end)
	-- 1
	```

	@within List
]=]

local function count<Value>(list: { Value }, predicate: ((Value, number) -> boolean)?): number
	return countImpl(list, predicate)
end

return count
