--!strict
local filter = require(script.Parent.filter)

return function()
	local dictionary: { [string]: number } = { a = 1, b = 2, c = 3, d = 4 }
	it("filter even", function()
		local result = filter(dictionary, function(value)
			return value % 2 == 0
		end)

		expect(result).toEqual({ b = 2, d = 4 })
	end)

	it("filter all", function()
		local result = filter(dictionary, function(_value)
			return false
		end)

		expect(result).toEqual({})
	end)
end
