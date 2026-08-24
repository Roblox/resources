--!strict

return function<K, V, K2, V2>(collection: { [K]: V }, mapper: (V, K) -> (V2, K2)): { [K2]: V2 }
	local new = {}

	for key, value in collection do
		local mappedValue, mappedKey = mapper(value, key)
		local newKey = if mappedKey == nil then key else mappedKey

		if mappedValue ~= nil then
			new[newKey] = mappedValue
		end
	end

	return new :: { [K2]: V2 }
end
