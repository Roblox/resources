--!strict
local minImpl = require(script.Parent.Parent.utils.min)
--[=[
	Returns the minimum value in this List.
	If any values are comparatively equivalent, the first one found will be returned.

	The `comparator` is used in the same way as `table.sort`. If it is not provided, the default comparator is `>`.

	```lua
	List.min({ 10, 200, 30 })
	-- 10

	List.min({ child, teen, adult }, function(personA, personB)
		return personA.age > personB.age
	end)
	-- child
	```

	@within List
]=]

local function min<Value>(list: { Value }, comparator: ((Value, Value) -> boolean)?): (Value, number?)
	return minImpl(list, comparator)
end

return min
