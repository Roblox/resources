--!strict
local keyOf = require(script.Parent.Parent.utils.keyOf)

--[=[
	Returns the index of the `value` if found within the List, otherwise returns nil.

	```lua
	List.indexOf({ "a", "b", "c" }, "b")
	-- 2
	```

	@within List
]=]

local function indexOf<Value>(list: { Value }, searchValue: Value): number?
	local key = keyOf(list, searchValue)
	return if key == nil then nil else key
end

return indexOf
