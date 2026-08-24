--!strict
local updateInImpl = require(script.Parent.Parent.utils.updateIn)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)

--[=[
	Returns a Dictionary with the entry at `keyPath` updated to the result of `updater`.

	If any entry does not exist along `keyPath`, an empty Dictionary will be created in its place.

	If the final entry does not exist, `updater` will be given `notSetValue` or nil.

	```lua
	local dictionary = {
		persons = {
			alice = {
				age = 10,
			},
		},
	}

	Dictionary.updateIn({ "persons", "alice", "age" }, function(value: number)
		assert(value, "will exist")
		return value + 1
	end)
	-- { persons = { alice = { age = 11 } } }
	```

	@within Dictionary
]=]

local function updateIn<Key, Value>(
	dictionary: { [any]: any },
	keyPath: { any },
	updater: (any) -> any,
	notSetValue: any?
): { [any]: any }
	return maybeFreeze(updateInImpl(dictionary, keyPath, updater, notSetValue))
end

return updateIn
