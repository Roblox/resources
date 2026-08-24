--!strict
local get = require(script.Parent.get)

--[=[
	Returns the last value in the List.

	Returns `notSetValue` if the List is empty.

	```lua
	List.last({ "a", "b", "c" })
	-- "c"

	List.last({ }, "default")
	-- "default"
	```

	@within List
]=]

local function last<Value>(list: { Value }, notSetValue: Value?): Value?
	return get(list, -1, notSetValue)
end

return last
