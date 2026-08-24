--!strict
return function(collection, key, value: any?)
	if collection[key] == value then
		return collection
	end

	local collectionCopy = table.clone(collection)
	collectionCopy[key] = value
	return collectionCopy
end
