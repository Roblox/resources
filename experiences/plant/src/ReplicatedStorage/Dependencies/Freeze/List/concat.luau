--!strict
local None = require(script.Parent.Parent.None)
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)

--[=[
	Returns a List of the same type concatenated to given arguments.

	```lua
	List.concat({ "a", "b", "c" }, { "d", "e", "f" })
	-- { "a", "b", "c", "d", "e", "f" }
	```

	@within List
]=]

local function concat<Value>(...: { Value }): { Value }
	local new = {}
	local index = 1

	for listIndex = 1, select("#", ...) do
		local list = select(listIndex, ...)

		if list ~= nil then
			if type(list) == "table" and #list > 0 then
				list = list
			else
				continue
			end

			for _, v in ipairs(list) do
				if v ~= None then
					new[index] = v
					index += 1
				end
			end
		end
	end

	return maybeFreeze(new)
end

return concat
