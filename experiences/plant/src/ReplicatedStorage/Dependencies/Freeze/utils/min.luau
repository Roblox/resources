--!nonstrict
local defaultComparator = function(a: any, b: any)
	return a > b
end

return function<K, V>(collection: { [K]: V }, comparator: ((V, V) -> boolean)?): (V, K)
	local useComparator = if comparator == nil then defaultComparator else comparator

	local highestKey: K
	local highestValue: V
	for key, value in collection do
		if highestValue == nil or useComparator(highestValue, value) == true then
			highestKey = key
			highestValue = value
		end
	end

	return highestValue :: V, highestKey :: K
end
