--!strict
local None = require(script.Parent.Parent.None)

return function(...: { [any]: any })
	local new = {}

	for dictionaryIndex = 1, select("#", ...) do
		local dictionary = select(dictionaryIndex, ...)

		if dictionary ~= nil then
			assert(type(dictionary) == "table", "Expected table")

			for key, value in dictionary do
				if value == None then
					new[key] = nil
				else
					new[key] = value
				end
			end
		end
	end

	return new
end
