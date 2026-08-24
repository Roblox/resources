--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)

local function removeSingle<Value>(list: { Value }, index: number): { Value }
	local len = #list
	local new = table.create(len - 1)
	if index < 1 then
		index += len + 1
	end

	if index <= 0 or index > len then
		-- out of bounds
		return list
	end

	local newIndex = 1

	for i, v in list do
		if i ~= index then
			new[newIndex] = v
			newIndex += 1
		end
	end

	return new
end

--[=[
	Returns a List which excludes this `index`. Values at indices above `index` are shifted down by 1 to fill the position.

	`index` may be a negative number, which indexes back from the end of the list.
	`list.remove(-1)` removes the last item in the list.

	If the given `given` results in an index that is out of bounds, it will return the original list with no changes.

	```lua
	List.remove({ "a", "b", "c", "d" }, 3)
	-- { "a", "b", "d" }
	```

	@within List
]=]

local function remove<Value>(list: { Value }, ...: number): { Value }
	local indicies = { ... }
	if #indicies == 1 then
		return removeSingle(list, indicies[1])
	end

	local willMutate = 0
	local len = #list
	local indicesToRemove = {}
	for _, index in indicies do
		if index < 1 then
			index += len + 1
		end

		if not (index <= 0 or index > len) then
			-- make sure we are in bounds
			indicesToRemove[index] = true
			willMutate += 1
		end
	end

	if willMutate == 0 then
		return list
	end

	local new = table.create(math.max(1, len - willMutate))

	local newIndex = 1

	for i, v in list do
		if not indicesToRemove[i] then
			new[newIndex] = v
			newIndex += 1
		end
	end

	return maybeFreeze(new)
end

return remove
