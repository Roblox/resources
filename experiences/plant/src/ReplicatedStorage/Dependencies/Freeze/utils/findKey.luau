local findPair = require(script.Parent.findPair)

return function<Key, Value>(collection: { [Key]: Value }, predicate)
	local entry, _ = findPair(collection, predicate)
	return entry
end
