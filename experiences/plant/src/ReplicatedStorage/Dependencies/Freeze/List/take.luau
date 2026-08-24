--!strict
local slice = require(script.Parent.slice)

--[=[
	Returns a List which includes the first `amount` of entires.

	```lua
	List.take({ "a", "b", "c", "d" }, 2)
	-- { "a", "b" }
	```

	@within List
]=]

local function take<Value>(list: { Value }, amount: number): { Value }
	return slice(list, 1, math.max(1, amount))
end

return take
