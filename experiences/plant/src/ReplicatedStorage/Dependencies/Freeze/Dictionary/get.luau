--!strict
--[=[
	Returns the value at the given key, otherwise returns `notSetValue` if the given value is not found.
	```lua
	Dictionary.get({ a = 1, b = 2, c = 3 }, "a")
	-- 1

	Dictionary.get({ a = 1, b = 2, c = 3 }, "foobar", "default")
	-- "default"
	```

	@within Dictionary
]=]

local function get<Key, Value>(dictionary: { [Key]: Value }, key: Key, notSetValue: Value?): Value?
	local value = dictionary[key]
	return if value then value else notSetValue
end

return get
