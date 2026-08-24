--!strict
--[=[
	Returns true if the collection is empty.

	```lua
	Freeze.isEmpty({})
	-- true
	```

	@within Freeze
	@function isEmpty
	@return boolean
]=]

return function(collection)
	return next(collection) == nil
end
