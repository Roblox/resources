--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a List excluding the first index in this `List`, shifting all other values to a lower index.

	If `amount` is not provided, it will default to 1.
	Passing an `amount` greater than the length of the given `List` will result in an empty List.

	```lua
	List.shift({ "a", "b", "c" })
	-- { "b", "c" }
	```

	@within List
]=]

local function shift<Value>(list: { Value }, amount: number?): { Value }
	local len = #list

	local numPlaces = math.min(len, amount or 1)

	local new = table.create(len - numPlaces)

	for i = 1 + numPlaces, len do
		new[i - numPlaces] = list[i]
	end

	return maybeFreeze(new)
end

return shift
