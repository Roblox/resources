--!strict
local reduceImpl = require(script.Parent.Parent.utils.reduce)

--[=[
	Returns the final reduced result by iterating the List and calling the `reducer` for every entry
	and passing along the reduced value.

	```lua
	List.reduce({ 10, 20, 30 }, function(reduction, value)
		return reduction + value
	end, 0)
	-- 60
	```

	@within List
]=]

local function reduce<Value, T>(list: { Value }, reducer: (T, Value, number) -> T, initialReduction: T): T
	return reduceImpl(list, reducer, initialReduction, false)
end

return reduce
