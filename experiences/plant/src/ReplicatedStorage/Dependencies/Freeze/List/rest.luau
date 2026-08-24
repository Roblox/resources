--!strict

local slice = require(script.Parent.slice)

--[=[
	Returns a List containing all entries except the first.

	Equivalent to `slice(2)`. See [List.slice] for more information.

	```lua
	List.rest({ "a", "b", "c" })
	-- { "b", "c" }
	```

	@within List
]=]

local function rest<Value>(list: { Value }): { Value }
	return slice(list, 2)
end

return rest
