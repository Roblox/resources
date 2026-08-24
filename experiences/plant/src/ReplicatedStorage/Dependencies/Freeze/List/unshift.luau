--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a List with the provided `values` prepended, shifting other values ahead to higher indices.

	```lua
	List.unshift({ "b", "c" }, "a")
	-- { "a", "b", "c" }
	```

	@within List
]=]

local function unshift<Value>(list: { Value }, ...: Value): { Value }
	local argCount = select("#", ...)

	local new = table.clone(list)

	for i = argCount, 1, -1 do
		local v = select(i, ...)
		table.insert(new, 1, v)
	end

	return maybeFreeze(new)
end

return unshift
