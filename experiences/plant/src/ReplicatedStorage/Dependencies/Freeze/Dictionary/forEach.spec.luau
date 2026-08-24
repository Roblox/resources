--!strict
local forEach = require(script.Parent.forEach)

return function()
	local dictionary = { a = 1, b = 2, c = 3, d = 4 }
	it("forEach break", function()
		local result = forEach(dictionary, function(value)
			return value < 2
		end)

		expect(result).toEqual(2)
	end)

	it("forEach no match", function()
		local result = forEach(dictionary, function(_value)
			return false
		end)

		expect(result).toEqual(1)
	end)

	it("forEach all match", function()
		local result = forEach(dictionary, function(_value)
			return true
		end)

		expect(result).toEqual(4)
	end)
end
