--!strict
local getInImpl = require(script.Parent.Parent.utils.getIn)
--[=[
	Returns the value if found by following a path of keys, otherwise returns `notSetValue` if the given value is nil.

	```lua
	local dictionary = { a = { b = "c" } }
	Dictionary.getIn(dictionary), { "a", "b" })
	-- "c"
	```

	@within Dictionary
]=]

local function getIn<Value>(dictionary: { [any]: any }, keyPath: { any }, notSetValue: Value?): Value?
	return getInImpl(dictionary, keyPath, notSetValue)
end

return getIn
