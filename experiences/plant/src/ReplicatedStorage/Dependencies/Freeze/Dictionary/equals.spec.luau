--!strict
local equals = require(script.Parent.equals)

return function()
	local list = { a = 1, b = 2, c = 3 }
	it("match reference", function()
		expect(equals(list, list)).toEqual(true)
	end)

	it("match value", function()
		expect(equals(list, { a = 1, b = 2, c = 3 })).toEqual(true)
	end)

	it("empty", function()
		expect(equals(list, {})).toEqual(false)
	end)

	it("no match", function()
		expect(equals(list, { a = 1, b = 3 })).toEqual(false)
	end)
end
