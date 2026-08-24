--!strict
local maxImpl = require(script.Parent.Parent.utils.max)

--[=[
	Returns the maximum value and key in this dictionary.
	If any values are comparatively equivalent, the first one found will be returned. (Order is undefined.)

	The `comparator` is used in the same way as `table.sort`. If it is not provided, the default comparator is `>`.

	```lua
	Dictionary.max({ a = 10, b = 200, c = 30 })
	-- ( 200, "c" )

	Dictionary.max({ alice = child, bertram = teen, charlie = adult }, function(personA, personB)
		return personA.age > personB.age
	end)
	-- ( adult, "charlie" )
	```

	@within Dictionary
]=]

local function max<Key, Value>(dictionary: { [Key]: Value }, comparator: ((Value, Value) -> boolean)?): (Value, Key?)
	return maxImpl(dictionary, comparator)
end

return max
