--!strict

local function count<Key, Value>(list: { [Key]: Value }, predicate: ((Value, Key) -> boolean)?)
	local sum = 0

	for key, value in list do
		if predicate == nil or predicate(value, key) then
			sum += 1
		end
	end

	return sum
end

return count
