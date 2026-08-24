--!strict
local equalsImpl = require(script.Parent.Parent.utils.equals)

--[=[
	Returns true if both Lists have value equality.

	```lua
	local list1 = { "a", "b", "c" }
	local list2 = { "a", "b", "c" }

	List.equals(list1, list2)
	-- true
	```

	@within List
]=]

local function equals<Value>(listA: { Value }, listB: any): boolean
	return equalsImpl(listA, listB)
end

return equals
