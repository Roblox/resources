--!strict
local slice = require(script.Parent.slice)

--[=[
	Returns a List which excludes the first `amount` of entries.

	```lua
	List.skip({ "a", "b", "c", "d" }, 2)
	-- { "c", "d" }
	```

	@within List
]=]

local function skip<Value>(list: { Value }, amount: number): { Value }
	return slice(list, math.max(1, amount + 1))
end

return skip
