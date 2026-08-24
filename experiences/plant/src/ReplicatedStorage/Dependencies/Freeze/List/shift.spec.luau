--!strict
local shift = require(script.Parent.shift)

return function()
	local list = { "a", "b", "c" }
	it("shift, no args", function()
		local result = shift(list)
		expect(result).toEqual({ "b", "c" })
	end)

	it("shift, number", function()
		local result = shift(list, 2)
		expect(result).toEqual({ "c" })
	end)

	it("shift, to empty", function()
		local result = shift(list, 3)
		expect(result).toEqual({})
	end)

	it("shift, out of bounds", function()
		local result = shift(list, 4)
		expect(result).toEqual({})
	end)
end
