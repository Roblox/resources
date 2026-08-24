--!strict
local some = require(script.Parent.some)

return function()
	local list = { a = 1, b = 2, c = 3 }
	it("match all", function()
		expect(some(list, function(value)
			return true
		end)).toEqual(true)
	end)

	it("no match", function()
		expect(some(list, function(value)
			return false
		end)).toEqual(false)
	end)

	it("one match", function()
		expect(some(list, function(value)
			return value == 2
		end)).toEqual(true)
	end)
end
