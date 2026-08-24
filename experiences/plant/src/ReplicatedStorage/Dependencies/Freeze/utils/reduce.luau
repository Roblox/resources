--!strict

local function reduce<Value, T>(collection: { Value }, reducer: (T, Value, number) -> T, reduction: T, reverse: boolean): T
	local back = #collection + 1

	for i, v in collection do
		v = if reverse then collection[back - i] else v

		reduction = reducer(reduction, v, i)
	end

	return reduction
end

return reduce
