--!strict
local getIn = require(script.Parent.Parent.utils.getIn)
local None = require(script.Parent.Parent.None)
--[=[
	Returns true if the value is found by following a path of keys.

	```lua
	local dictionary = { a = { b = "c" } }
	Dictionary.hasIn(dictionary, { "a", "b" })
	-- true
	```

	@within Dictionary
]=]

local function hasIn<Key, Value>(dictionary: { [Key]: Value }, keyPath: { any }): boolean
	return getIn(dictionary, keyPath, None) ~= None
end

return hasIn
