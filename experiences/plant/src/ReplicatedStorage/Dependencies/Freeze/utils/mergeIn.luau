--!strict
local updateIn = require(script.Parent.updateIn)
local merge = require(script.Parent.merge)

return function(collection: { [any]: any }, keyPath, ...)
	local args = { ... }
	return updateIn(collection, keyPath, function(m)
		return merge(m, table.unpack(args))
	end, {})
end
