--!strict
local set = require(script.Parent.Parent.utils.set)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a Dictionary which excludes the given `keys`.

	```lua
	Dictionary.remove({ a = 10, b = 20, c = 30 }).remove("c")
	-- { a = 10, b = 20 }

	Dictionary.remove({ a = 10, b = 20, c = 30 }).remove("b", "c")
	-- { a = 10 }
	```

	@within Dictionary
]=]

local function remove<Key, Value>(dictionary: { [Key]: Value }, ...: Key): { [Key]: Value }
	local new = table.clone(dictionary)
	for _, key in { ... } do
		new = set(new, key, nil)
	end
	return maybeFreeze(new)
end

return remove
