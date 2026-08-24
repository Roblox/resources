--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a new map where keys and values are flipped.

	```lua
	Dictionary.flip({ a = "x", b = "y", c = "z" )
	-- { x = "a", y = "b", z = "c" }
	```

	@within Dictionary
]=]

local function flip<Key, Value>(dictionary: { [Key]: Value }): { [Value]: Key }
	local new = {}

	for key, value in dictionary do
		new[value] = key
	end

	return maybeFreeze(new)
end

return flip
