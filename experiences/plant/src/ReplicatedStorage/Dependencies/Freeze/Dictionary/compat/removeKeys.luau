--!strict
local remove = require(script.Parent.Parent:FindFirstChild("remove"))
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within Dictionary
	@deprecated v0.0.4 -- Use [Dictionary.remove] instead.
]=]

local function removeKeys<Key, Value>(dictionary: { [Key]: Value }, ...: Key): { [Key]: Value }
	deprecationWarning("Dictionary." .. script.Name, "Dictionary.remove")
	return remove(dictionary, ...)
end

return removeKeys
