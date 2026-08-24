--!strict
local maybeFreeze = require(script.Parent.Parent.utils.maybeFreeze)
--[=[
	Returns a new map having removed the all pairs with the given `value`.

	```lua
	Dictionary.removeValue({ a = 10, b = 20, c = 30 }, 10)
	-- { b = 20, c = 30 }
	```

	@within Dictionary
]=]

local function removeValue<Key, Value>(dictionary: { [Key]: Value }, value: Value): { [Key]: Value }
	local new = {}

	local mutated = false
	for k, v in dictionary do
		if v == value then
			mutated = true
		else
			new[k] = v
		end
	end

	return if mutated then maybeFreeze(new) else dictionary
end

return removeValue
