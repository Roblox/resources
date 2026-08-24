--!strict
local setIn = require(script.Parent.setIn)

return function(collection, keyPath)
	return setIn(collection, keyPath, nil)
end
