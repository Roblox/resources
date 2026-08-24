local updateIn = require(script.Parent.updateIn)
local None = require(script.Parent.Parent.None)

return function(collection, keyPath, value)
	return updateIn(collection, keyPath, function()
		return value
	end, None)
end
