--!strict
local merge = require(script.Parent.Parent.merge)
local deprecationWarning = require(script.Parent.Parent.Parent.utils.deprecationWarning)

--[=[
	@within Dictionary
	@deprecated v0.0.4 -- Use [Dictionary.merge] instead.
]=]

local function join<Key, Value>(...: { [Key]: Value }): { [any]: any }
	deprecationWarning("Dictionary." .. script.Name, "Dictionary.merge")
	return merge(...)
end

return join
