--!strict
local findPair = require(script.Parent.findPair)

return function()
	local dictionary: { [string]: number } = { a = 1, b = 2, c = 3 }
	it("findPair match", function()
		local foundKey, foundValue = findPair(dictionary, function(value)
			return value % 2 == 0
		end)

		expect(foundKey).toEqual("b")
		expect(foundValue).toEqual(2)
	end)

	it("findPair no match", function()
		local foundKey, foundValue = findPair(dictionary, function(value)
			return value == 4
		end)

		expect(foundKey).toEqual(nil)
		expect(foundValue).toEqual(nil)
	end)
end
