--!strict
--[=[
	Joins values together as a string, inserting a separator between each.

	The default separator is `","`.

	```lua
	List.joinAsString({ "a", "b", "c" }, ", ")
	-- "a, b, c"
	```

	@within List
]=]

local function joinAsString<Value>(list: { Value }, separator: string?): string
	return table.concat(list, separator or ",")
end

return joinAsString
