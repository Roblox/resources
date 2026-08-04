--!strict

--[[
	Merges all arrays into one array, eliminating duplicate values
--]]

local function mergeArraysUniqueOnly(...: { any })
	local results = {}

	for _, array in ipairs({ ... }) do
		if not array then
			continue
		end
		for _, value in ipairs(array) do
			if not table.find(results, value) then
				table.insert(results, value)
			end
		end
	end

	return results
end

return mergeArraysUniqueOnly
