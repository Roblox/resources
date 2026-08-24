--!strict
local mergeImpl = require(script.Parent.Parent.utils.merge)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a merged result of all given dictionaries.

	If `Freeze.None` is a value assigned to a key, it will delete that key from the resulting dictionary.

	```lua
	Dictionary.merge({ a = 10, b = 20 }, { c = 30 })
	-- { a = 10, b = 20, c = 30 }

	Dictionary.merge({ a = 10, b = 20 }, { c = 30, d = 40 }, { b = Freeze.None })
	-- { a = 10, c = 30, d = 40 }
	```

	@within Dictionary
]=]

local function merge<Key, Value>(...: { [Key]: Value }): { [any]: any }
	return maybeFreeze(mergeImpl(...))
end

return merge
