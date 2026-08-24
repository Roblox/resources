--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a List with the provided `values` appended at the end of the List.

	```lua
	List.push({ 10, 20, 30 }, 40, 50, 60)
	-- { 10, 20, 30, 40, 50, 60 }
	```

	@within List
]=]

local function push<Value>(list: { Value }, ...: Value): { Value }
	if #{ ... } == 0 then
		return list
	end

	local newCollection = table.clone(list)
	for _, value in { ... } do
		table.insert(newCollection, value)
	end

	return maybeFreeze(newCollection)
end

return push
