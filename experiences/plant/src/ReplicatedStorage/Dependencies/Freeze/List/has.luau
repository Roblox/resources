--!strict
--[=[
	Returns true if the `index` exists within the List.

	```lua
	List.has({ "a", "b", "c" }, 2)
	-- true
	```

	@within List
]=]

local function has<Value>(list: { Value }, index: number): boolean
	return list[index] ~= nil
end

return has
