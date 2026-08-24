--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a List in reverse order.

	```lua
	List.reverse({ "a", "b", "c" })
	-- { "c", "b", "a" }
	```

	@within List
]=]

local function reverse<Value>(list: { Value }): { Value }
	local len = #list
	local new = table.create(len)

	local back = len + 1

	for i, _ in list do
		new[i] = list[back - i]
	end

	return maybeFreeze(new)
end

return reverse
