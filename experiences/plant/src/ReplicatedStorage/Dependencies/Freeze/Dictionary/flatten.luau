--!nonstrict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)

local function flattenImpl(dictionary: { [any]: any }, depth: number?)
	local new = {}

	for key, value in dictionary do
		if type(value) == "table" and (not depth or depth > 0) then
			local subDictionary = flattenImpl(value, depth and depth - 1)

			for newKey, newValue in pairs(new) do
				subDictionary[newKey] = newValue
			end

			new = subDictionary
		else
			new[key] = value
		end
	end

	return new
end

--[=[
	Returns a flattened dictionary by combining keys of the lowest depth.

	If provided `depth`, the flattening will early-out.

	```lua
	Dictionary.flatten({
		foo = 1,
		foobar = {
			bar = 2,
			baz = {
				etc = 3,
			},
		},
	})
	-- { foo = 1, bar = 2, etc = 3 }
	```

	@within Dictionary
]=]

local function flatten(dictionary: { [any]: any }, depth: number?): { [any]: any }
	return maybeFreeze(flattenImpl(dictionary, depth))
end

return flatten
