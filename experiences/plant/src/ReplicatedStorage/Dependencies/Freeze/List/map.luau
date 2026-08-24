--!strict
local mapImpl = require(script.Parent.Parent.utils.map)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)

--[=[
	Returns a List with values passed through a `mapper` function.

	Returning a second `value` in the mapper function will reassign the index.

	If `mapper` returns nil, the entry will be filtered.

	```lua
	List.map({ 1, 2, 3 }, function(value, index)
		return value * 10
	end)
	-- { 10, 20, 30 }
	```

	@within List
]=]

local function map<Value, NewValue>(list: { Value }, mapper: (Value, number) -> (NewValue, number?)): { NewValue }
	return maybeFreeze(mapImpl(list, mapper))
end

return map
