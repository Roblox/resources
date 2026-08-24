--!strict
local equalsDeep = require(script.Parent.equalsDeep)

return function(a, b)
	return equalsDeep(a, b)
end
