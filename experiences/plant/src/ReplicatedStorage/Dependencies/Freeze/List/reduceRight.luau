--!strict
local reduce = require(script.Parent.Parent.utils.reduce)

--[=[
	Returns the final reduced result by iterating the list in reverse (from the right side) and calling the `reducer` for every entry
	and passing along the reduced value.

	```lua
	List.reduceRight({ "a", "b", "c" }, function(reduction, value)
		return reduction .. value
	end, "")
	-- "cba"
	```

	@within List
]=]

local function reduceRight<Value, T>(list: { Value }, reducer: (T, Value, number) -> T, initialReduction: T): T
	return reduce(list, reducer, initialReduction, true)
end

return reduceRight
