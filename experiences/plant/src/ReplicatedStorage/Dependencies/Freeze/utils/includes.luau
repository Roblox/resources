--!strict

return function<Key, Value>(collection: { [Key]: Value }, value)
	for _, v in collection do
		if v == value then
			return true
		end
	end

	return false
end
