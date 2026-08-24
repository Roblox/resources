--!strict

return function<Key, Value>(collection: { [Key]: Value }, predicate: (Value, Key) -> boolean): (Key?, Value?)
	for k, v in collection do
		if predicate(v, k) == true then
			return k, v
		end
	end

	return nil
end
