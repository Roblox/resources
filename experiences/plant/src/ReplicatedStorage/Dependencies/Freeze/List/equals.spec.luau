--!strict
local equals = require(script.Parent.equals)

return function()
	local list = { "a", "b", "c" }
	it("match reference", function()
		expect(equals(list, list)).toEqual(true)
	end)

	it("match value", function()
		expect(equals(list, { "a", "b", "c" })).toEqual(true)
	end)

	it("empty", function()
		expect(equals(list, {})).toEqual(false)
	end)

	it("no match", function()
		expect(equals(list, { "x", "y", "z" })).toEqual(false)
	end)
end
