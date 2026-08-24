--!strict
--[=[
	Joins values together as a string, inserting a separator between each.

	The default separator is `","`.

	```lua
	Dictionary.joinAsString({ a = 1, b = 2, c = 3 }, ", ")
	-- "a=1, b=2, c=3"
	```

	@within Dictionary
]=]

local function joinAsString<Key, Value>(dictionary: { [Key]: Value }, separator: string?): string
	local fields = {}
	for k, v in dictionary do
		table.insert(fields, string.format("%s=%s", tostring(k), tostring(v)))
	end
	return table.concat(fields, separator or ",")
end

return joinAsString
