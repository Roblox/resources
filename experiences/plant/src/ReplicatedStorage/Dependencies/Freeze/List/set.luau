--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a List which includes `value` at `index`.
	If `index` already exists, it will be replaced.

	Returns the original List if no changes were made.

	```lua
	List.set({"a", "b", "c"}, 1, "A")
	-- { "A", "b", "c" }
	```

	@within List
]=]

local function set<Value>(list: { Value }, index: number, value: Value): { Value }
	if list[index] == value then
		return list
	end

	local newList = table.clone(list)
	newList[index] = value
	return maybeFreeze(newList)
end

return set
