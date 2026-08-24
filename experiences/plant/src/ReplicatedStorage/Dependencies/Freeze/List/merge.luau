--!strict
local mergeImpl = require(script.Parent.Parent.utils.merge)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)

--[=[
	Returns a merged result of all given Lists.

	If `Freeze.None` is a value assigned to an index, it will delete that index from the resulting List.

	```lua
	List.merge({ 10, nil, 30 }, { nil, 20, nil })
	-- { 10, 20, 30 }

	List.merge({ "a", "b", "c" }, { "x" }, { nil, "y", Freeze.None })
	-- { "x", "y" }
	```

	@within List
]=]

local function merge(...: { any }): { any }
	return maybeFreeze(mergeImpl(...))
end

return merge
