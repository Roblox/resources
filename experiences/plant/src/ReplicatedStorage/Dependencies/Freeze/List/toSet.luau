--!strict

--[=[
	Returns a Set from the given List.

	@within List
	@function toSet
	@ignore
]=]
return function<Value>(list: { Value }): { [Value]: boolean }
	local set = {}

	for _, v in list do
		set[v] = true
	end

	return set
end
