--!strict
local findKey = require(script.Parent.findKey)

return function()
	local dictionary: { [string]: number } = { a = 1, b = 2, c = 3 }
	it("findKey match", function()
		local result = findKey(dictionary, function(value)
			return value % 2 == 0
		end)

		expect(result).toEqual("b")
	end)

	it("findKey no match", function()
		local result = findKey(dictionary, function(value)
			return value == 4
		end)

		expect(result).toEqual(nil)
	end)

	it("findKey no match, default", function()
		local result = findKey(dictionary, function(value)
			return value == 4
		end, "d")

		expect(result).toEqual("d")
	end)
end
