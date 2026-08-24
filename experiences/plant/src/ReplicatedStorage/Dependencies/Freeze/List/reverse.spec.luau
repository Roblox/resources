--!strict
local reverse = require(script.Parent.reverse)

return function()
	local list = { "a", "b", "c" }
	it("reverse", function()
		expect(reverse(list)).toEqual({ "c", "b", "a" })
	end)
end
