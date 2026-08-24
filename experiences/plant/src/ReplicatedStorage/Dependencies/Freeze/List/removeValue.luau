--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
local toSet = require(script.Parent.toSet)

local function removeValues<Value>(list: { Value }, ...: Value)
	local valuesSet = toSet({ ... })

	local new = {}
	local index = 1

	local didMutate = false
	for _, v in ipairs(list) do
		if not valuesSet[v] then
			didMutate = true
			new[index] = v
			index += 1
		end
	end

	return if didMutate then maybeFreeze(new) else list
end
--[=[
	Returns a List having removed all entries with the given `value`.

	If no values are present, it will return the original List with no changes.

	```lua
	List.removeValue({ "a", "b", "c" }, "a")
	-- { "b", "c" }
	```

	@within List
]=]

local function removeValue<Value>(list: { Value }, ...: Value): { Value }
	local values = { ... }
	if #values == 1 then
		local value = values[1]
		local new = table.create(#list)

		local didRemove = false
		for _, v in list do
			if v == value then
				didRemove = true
			else
				table.insert(new, v)
			end
		end

		return if didRemove then maybeFreeze(new) else list
	else
		return removeValues(list, ...)
	end
end

return removeValue
