--!strict
local includesImpl = require(script.Parent.Parent.utils.includes)
--[=[
	Returns true if the `value` is found within the List.

	```lua
	List.includes({ "a", "b", "c" }, "b")
	-- true
	```

	@within List
]=]

local function includes<Value>(list: { Value }, query: Value): boolean
	return includesImpl(list, query)
end

return includes
