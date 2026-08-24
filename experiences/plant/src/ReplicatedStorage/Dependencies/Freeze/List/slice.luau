--!strict
local sliceImpl = require(script.Parent.Parent.utils.slice)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a List that includes the range `[from, to)`.

	If `from` is negative, it is offset from the end of the list.
	`slice(-2)` returns a list of the last two entries.
	If it is not provided, the new list will begin at the first entry.

	If `to` is negative, it is offset from the end of the list.
	`slice(1, -1)` returns a list of everything but the last entry.
	If it is not provided, the new list will continue through the end of the list.

	```lua
	List.slice({ "a", "b", "c" }, 2)
	-- { "b", "c" }

	List.slice({ "a", "b", "c" }, -1)
	-- { "c" }

	List.slice({ "a", "b", "c" }, 1, -1)
	-- { "a", "b" }
	```

	@within List
]=]

local function slice<Value>(list: { Value }, from: number?, to: number?): { Value }
	return maybeFreeze(sliceImpl(list, from, to))
end

return slice
