--!strict
return function(maybeValue)
	return if maybeValue
			and typeof(maybeValue) == "table"
			and typeof(maybeValue.equals) == "function"
		then true
		else false
end
