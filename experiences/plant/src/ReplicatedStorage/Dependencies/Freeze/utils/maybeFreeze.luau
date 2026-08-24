--!strict

-- Tables that are frozen cannot be re-frozen.
-- This helper function ensures we prevent this from happening
return function(t)
	if table.isfrozen(t) then
		return t
	else
		return table.freeze(t)
	end
end
