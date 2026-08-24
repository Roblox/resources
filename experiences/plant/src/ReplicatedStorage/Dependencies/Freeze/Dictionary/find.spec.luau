--!strict
local find = require(script.Parent.find)

return function()
	local dictionary: { [string]: number } = { a = 1, b = 2, c = 3 }
	it("find match", function()
		local result = find(dictionary, function(value)
			return value % 2 == 0
		end)

		expect(result).toEqual(2)
	end)

	it("find no match", function()
		local result = find(dictionary, function(value)
			return value == 4
		end)

		expect(result).toEqual(nil)
	end)

	it("find no match, default value", function()
		local result = find(dictionary, function(value)
			return value == 4
		end, -100)

		expect(result).toEqual(-100)
	end)
end
