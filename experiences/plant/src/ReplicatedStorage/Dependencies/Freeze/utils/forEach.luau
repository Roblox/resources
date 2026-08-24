--!strict

return function<Key, Value>(collection, sideEffect: (Value, Key) -> boolean): number
	local timesCalled = 0
	for k, v in collection do
		timesCalled += 1
		if sideEffect(v, k) == false then
			break
		end
	end

	return timesCalled
end
