--!strict
local equalsImpl = require(script.Parent.Parent.utils.equals)

--[=[
	Returns true if both Dictionaries have _value_ equality.

	:::info

	If you only require reference equal, use the `==` operator.

	:::

	```lua
	local dictionary1 = { a = 1, b = 2, c = 3 }
	local dictionary2 = { a = 1, b = 2, c = 3 }

	Dictionary.equals(dictionary1, dictionary2)
	-- true
	```

	@within Dictionary
]=]
local function equals<Key, Value>(dictionaryA: { [Key]: Value }, dictionaryB: any): boolean
	return equalsImpl(dictionaryA, dictionaryB)
end

return equals
