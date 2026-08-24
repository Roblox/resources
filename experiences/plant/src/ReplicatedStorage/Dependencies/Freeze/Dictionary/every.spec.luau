--!strict
local every = require(script.Parent.every)

return function()
	local dictionary = { a = 1, b = 2, c = 3 }
	it("match", function()
		expect(every(dictionary, function(value)
			return type(value) == "number"
		end)).toEqual(true)
	end)

	it("no match", function()
		expect(every(dictionary, function(value)
			return false
		end)).toEqual(false)
	end)
end
