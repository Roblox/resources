--!strict
local isImmutable = require(script.Parent.isImmutable)
local isDataStructure = require(script.Parent.isDataStructure)

return function(collection, key): boolean
	return if isImmutable(collection)
		then collection:has(key)
		else isDataStructure(collection) and collection[key] ~= nil
end
