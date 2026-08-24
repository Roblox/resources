--!strict
local updateIn = require(script.Parent.updateIn)

--[=[
	Returns a List with the entry at `index` updated to the result of `updater`.

	If the entry does not exist, `updater` will be given `notSetValue` or nil.

	```lua
	List.update({ "a", "b", "c" }, 2, function(value)
		return string.rep(value, 5)
	end)
	-- { "a", "bbbbb", "c" }

	List.update({ "a", "b", "c" }, 4, function(value)
		return string.rep(value, 5)
	end, "d")
	-- { "a", "b", "c", "ddddd" }
	```

	@within List
]=]

local function update<Value>(list: { Value }, index: number, updater: (Value?) -> Value, notSetValue: Value?): { Value }
	return updateIn(list, { index }, updater, notSetValue)
end

return update
