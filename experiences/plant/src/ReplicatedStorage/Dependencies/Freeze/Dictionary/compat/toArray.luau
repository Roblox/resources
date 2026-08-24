--!strict
local values = require(script.Parent.Parent.values)
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within Dictionary
	@deprecated v0.0.4 -- Use [Dictionary.values] instead.
]=]

local function toArray<Key, Value>(dictionary: { [Key]: Value }): { Value }
	deprecationWarning("Dictionary." .. script.Name, "Dictionary.values")
	return values(dictionary)
end

return toArray
