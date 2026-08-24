--!strict
local forEach = require(script.Parent.forEach)

return function()
	local list = { 1, 2, 3, 4 }
	it("forEach break", function()
		local result = forEach(list, function(value)
			return value < 2
		end)

		expect(result).toEqual(2)
	end)

	it("forEach no match", function()
		local result = forEach(list, function(_value)
			return false
		end)

		expect(result).toEqual(1)
	end)

	it("forEach all match", function()
		local result = forEach(list, function(_value)
			return true
		end)

		expect(result).toEqual(4)
	end)
end
