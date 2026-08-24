--!strict
local slice = require(script.Parent.slice)

--[=[
	Returns a List containing all entires except the last.

	Equivalent to `slice(1, -1)`. See [List.slice] for more information.

	```lua
	List.butLast({ 1, 2, 3 })
	-- { 1, 2 }
	```

	@within List
]=]

local function butLast<Value>(list: { Value }): { Value }
	return slice(list, 1, -1)
end

return butLast
