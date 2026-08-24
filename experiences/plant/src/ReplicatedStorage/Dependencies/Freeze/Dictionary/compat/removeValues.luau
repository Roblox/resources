--!strict
local removeValue = require(script.Parent.Parent.removeValue)
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within Dictionary
	@deprecated v0.0.4 -- Use [Dictionary.removeValue] instead.
]=]

local function removeValues<Key, Value>(dictionary: { [Key]: Value }, ...: Value): { [Key]: Value }
	deprecationWarning("Dictionary." .. script.Name, "Dictionary.removeValue")
	return removeValue(dictionary, ...)
end

return removeValues
