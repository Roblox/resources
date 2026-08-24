--!strict

return function<Key, Value>(collection: { [Key]: Value }, predicate: (Value, Key) -> boolean)
	for i, v in collection do
		if predicate(v, i) == true then
			return true
		end
	end

	return false
end
