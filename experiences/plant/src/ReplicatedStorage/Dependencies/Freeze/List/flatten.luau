--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)

type ListOf<Value> = Value | { ListOf<Value> }

--[=[
	Returns a flattened list in the same index-order as each Value would appear.

	```lua
	List.flatten({
		"foo",
		{
			"bar",
			"baz",
		},
		{
			"bar",
			"baz",
		},
		"quz",
	})
	-- { "foo", "bar", "baz", "bar", "baz", "quz" }
	```

	@within List
]=]
local function flatten<Value>(list: { ListOf<Value> }, depth: number?): { ListOf<Value> }
	local new = {}
	local index = 1

	for _, v in list do
		if type(v) == "table" and (not depth or depth > 0) then
			local subList = flatten(v, depth and depth - 1)

			for j = 1, #subList do
				new[index] = subList[j]
				index = index + 1
			end
		else
			new[index] = v
			index = index + 1
		end
	end

	return maybeFreeze(new)
end

return flatten
