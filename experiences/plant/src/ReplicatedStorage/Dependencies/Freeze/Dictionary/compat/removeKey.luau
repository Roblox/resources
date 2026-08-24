--!strict
local remove = require(script.Parent.Parent:FindFirstChild("remove"))
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within Dictionary
	@deprecated v0.0.4 -- Use [Dictionary.remove] instead.
]=]

local function removeKey<Key, Value>(dictionary: { [Key]: Value }, key: Key): { [Key]: Value }
	deprecationWarning("Dictionary." .. script.Name, "Dictionary.remove")
	return remove(dictionary, key)
end

return removeKey
