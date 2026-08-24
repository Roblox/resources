--!strict
local slice = require(script.Parent.slice)
--[=[
	Returns a List which includes the last `amount` of entires.

	```lua
	List.takeLast({ "a", "b", "c" }, 2)
	-- { "b", "c" }
	```

	@within List
]=]

local function takeLast<Value>(list: { Value }, amount: number): { Value }
	return slice(list, -math.max(1, amount))
end

return takeLast
