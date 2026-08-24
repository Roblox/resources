--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a List excluding the last `index` of this List.

	This will repeat multiple times if given the optional `amount` argument and will always pop at least once.


	```lua
	List.pop({ 10, 20, 30 })
	-- { 10, 20 }

	List.pop({ 10, 20, 30 }, 2)
	-- { 10 }
	```

	@within List
]=]

local function pop<Value>(list: { Value }, amount: number?): { Value }
	local useAmount = math.max(1, amount or 1)

	local len = #list

	local new = table.create(len)

	for i = 1, len - useAmount do
		new[i] = list[i]
	end

	return maybeFreeze(new)
end

return pop
