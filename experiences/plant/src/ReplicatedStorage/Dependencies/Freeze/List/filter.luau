--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a new List of only entries for which the `predicate` function returns true.

	```lua
	List.filter({ 1, 2, 3, 4 }, function(value, key)
		return value % 2 == 0
	end)
	-- { 2, 4 }
	```

	@within List
]=]

local function filter<Value>(list: { Value }, predicate: (Value, number) -> boolean): { Value }
	local new = table.create(#list)

	for i, v in list do
		if predicate(v, i) then
			table.insert(new, v)
		end
	end

	return maybeFreeze(new)
end

return filter
