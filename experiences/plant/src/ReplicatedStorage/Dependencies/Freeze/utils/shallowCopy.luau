--!strict
local isImmutable = require(script.Parent.isImmutable)

return function(from)
	if isImmutable(from) then
		return from:clone()
	else
		return table.clone(from)
	end
end
