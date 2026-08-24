--!strict
local filterNot = require(script.Parent.filterNot)

return function()
	local dictionary: { [string]: number } = { a = 1, b = 2, c = 3, d = 4 }
	it("filterNot even", function()
		local result = filterNot(dictionary, function(value)
			return value % 2 == 0
		end)

		expect(result).toEqual({ a = 1, c = 3 })
	end)

	it("filterNot all", function()
		local result = filterNot(dictionary, function(_value)
			return false
		end)

		expect(result).toEqual({ a = 1, b = 2, c = 3, d = 4 })
	end)
end
