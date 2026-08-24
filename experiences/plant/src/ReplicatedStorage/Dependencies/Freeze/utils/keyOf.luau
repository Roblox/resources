local findKey = require(script.Parent.findKey)
local is = require(script.Parent.is)

return function(collection, searchValue)
	return findKey(collection, function(value)
		return is(value, searchValue)
	end)
end
