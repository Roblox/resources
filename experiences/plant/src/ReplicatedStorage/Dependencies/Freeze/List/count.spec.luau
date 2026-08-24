--!strict
local count = require(script.Parent.count)

return function()
	local list = { "a", "b", "c" }
	it("count", function()
		expect(count(list)).toEqual(3)
	end)

	it("predicate", function()
		expect(count(list, function(value)
			return value == "b"
		end)).toEqual(1)
	end)
end
