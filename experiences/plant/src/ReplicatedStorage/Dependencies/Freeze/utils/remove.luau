--!strict
local isImmutable = require(script.Parent.isImmutable)
local isDataStructure = require(script.Parent.isDataStructure)
local shallowCopy = require(script.Parent.shallowCopy)

return function(collection, key)
	if not isDataStructure(collection) then
		error("Cannot update non-data-structure value: " .. tostring(collection))
	end

	if isImmutable(collection) then
		if not collection.remove then
			error("Cannot update immutable value without .remove() method: " .. tostring(collection))
		end
		return collection:remove(key)
	end

	if not collection[key] then
		return collection
	end

	local collectionCopy = shallowCopy(collection)
	if #collectionCopy > 0 then
		table.remove(collection, key)
	else
		collection[key] = nil
	end

	return collectionCopy
end
