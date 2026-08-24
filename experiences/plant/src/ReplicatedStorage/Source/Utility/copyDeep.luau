--!strict

--[[
	Creates and returns a copy of the given table and any nested tables.
	If given a non-table type, it just returns the given value.
	Uses table.clone under the hood, which preserves metatables, but does not clone the metatable.
--]]

local function copyDeep<T>(source: T): T
	if typeof(source) == "table" then
		local copied = table.clone(source)
		for key, value in pairs(copied) do
			if typeof(value) == "table" then
				copied[key] = copyDeep(value)
			end
		end
		return (copied :: any) :: T
	else
		-- This is included so we can use a generic type T, since at the time of writing,
		-- there is no way to specify generic tables with mixed key types or value types.
		return source
	end
end

return copyDeep
