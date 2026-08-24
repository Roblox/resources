--!strict
local mergeInImpl = require(script.Parent.Parent.utils.mergeIn)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)

--[=[
	A combination of `updateIn` and `merge`, returning a new dictionary,
	but performing a merge at the point arrived by following the key path.

	```lua
	local dictionary = {
		persons = {
			alice = {
				age = 10,
			},
		},
	}

	Dictionary.mergeIn(dictionary, { "persons", "alice" }, { age = 11 })
	-- { persons = { alice = { age = 11 } } }
	```

	@within Dictionary
]=]

local function mergeIn(dictionary: { [any]: any }, keyPath: { any }, ...: any): { [any]: any }
	return maybeFreeze(mergeInImpl(dictionary, keyPath, ...))
end

return mergeIn
