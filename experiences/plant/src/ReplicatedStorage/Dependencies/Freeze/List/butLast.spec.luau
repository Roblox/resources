--!strict
local butLast = require(script.Parent.butLast)

return function()
	local list = { "a", "b", "c" }
	it("butLast", function()
		expect(butLast(list)).toEqual({ "a", "b" })
	end)
end
