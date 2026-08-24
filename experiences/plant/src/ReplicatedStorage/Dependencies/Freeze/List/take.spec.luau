--!strict
local take = require(script.Parent.take)

return function()
	local list = { "a", "b", "c" }
	it("exactly 1", function()
		expect(take(list, 1)).toEqual({ "a" })
	end)

	it("more than 1", function()
		expect(take(list, 2)).toEqual({ "a", "b" })
	end)
end
