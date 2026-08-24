--!strict
local count = require(script.Parent.count)

return function()
	local dictionary = { a = 1, b = 2, c = 3 }
	it("count", function()
		expect(count(dictionary)).toEqual(3)
	end)

	it("predicate", function()
		expect(count(dictionary, function(value)
			return value == 2
		end)).toEqual(1)
	end)
end
