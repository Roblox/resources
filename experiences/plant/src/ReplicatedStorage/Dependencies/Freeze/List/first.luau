--!strict
local get = require(script.Parent.get)

--[=[
	Returns the first value in the list.

	```lua
	List.first({ "a", "b", "c" })
	-- "a"
	```

	@within List
]=]

local function first<Value>(list: { Value }, notSetValue: Value?)
	return get(list, 1, notSetValue)
end

return first
