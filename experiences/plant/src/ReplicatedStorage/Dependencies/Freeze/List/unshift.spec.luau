--!strict
local unshift = require(script.Parent.unshift)

return function()
	local list = { "a", "b", "c" }
	it("should unshift 1 value", function()
		expect(unshift(list, "x")).toEqual({ "x", "a", "b", "c" })
	end)

	it("should unshift 3 values", function()
		expect(unshift(list, "x", "y", "z")).toEqual({ "x", "y", "z", "a", "b", "c" })
	end)
end
