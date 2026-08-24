--!strict

return function(collection, predicate)
	for i, v in collection do
		if predicate(v, i) == false then
			return false
		end
	end

	return true
end
