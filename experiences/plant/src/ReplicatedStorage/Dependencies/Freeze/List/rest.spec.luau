--!strict
local rest = require(script.Parent.rest)

return function()
	local list = { "a", "b", "c" }
	it("rest", function()
		expect(rest(list)).toEqual({ "b", "c" })
	end)
end
