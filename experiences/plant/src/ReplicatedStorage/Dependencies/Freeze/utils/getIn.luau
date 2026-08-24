--!strict
local None = require(script.Parent.Parent.None)
local get = require(script.Parent.get)

return function<Value>(collection: { [any]: any }, keyPath: { any }, notSetValue: Value?): Value?
	local node: any = collection
	local i = 0
	while i ~= #keyPath do
		i += 1
		node = get(node, keyPath[i], None)
		if node == None then
			return notSetValue
		end
	end

	return node
end
