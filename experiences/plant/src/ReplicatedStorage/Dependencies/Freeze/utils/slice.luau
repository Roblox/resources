--!strict
local function slice(list, from: number?, to: number?)
	local len = #list
	local derivedFrom = if from and from < 0 then len + (from + 1) else from or 1
	local derivedTo = if to and to < 0 then len + to else to or len

	if derivedFrom == 1 and derivedTo == #list then
		return list
	end

	local new = {}
	local index = 1
	for i = derivedFrom, derivedTo do
		new[index] = list[i]
		index = index + 1
	end

	return new
end

return slice
