--!strict
local setInImpl = require(script.Parent.Parent.utils.setIn)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a dictionary having set `value` at this `keyPath`.
	If any keys in `keyPath` do not exist, a new dictionary will be created at that key.

	```lua
	local dictionary = {
		persons = {
			alice = {
				age = 10,
			}
		},
	}

	Dictionary.setIn(dictionary, { "persons", "alice", "age" }, 11)
	-- { persons = { alice = { age = 11 } } }
	```

	@within Dictionary
]=]

local function setIn(dictionary: { [any]: any }, keyPath: { any }, value: any): { [any]: any }
	return maybeFreeze(setInImpl(dictionary, keyPath, value))
end

return setIn
