--!strict
local countImpl = require(script.Parent.Parent.utils.count)

--[=[
	Returns the number of pairs that match the `predicate`.
	If the `predicate` is not given, all pairs will be considered a match.

	```lua
	Dictionary.count({ a = 1, b = 2, c = 3 }).count()
	-- 3

	Dictionary.count({ a = 1, b = 2, c = 3 }, function(value, key)
		return value % 2 == 0
	end)
	-- 1
	```

	@within Dictionary
]=]
local function count<Key, Value>(dictionary: { [Key]: Value }, predicate: ((Value, Key) -> boolean)?): number
	return countImpl(dictionary, predicate)
end

return count
