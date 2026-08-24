--!strict
local joinAsString = require(script.Parent.joinAsString)

return function()
	local list = { "a", "b", "c" }
	it("joinAsString", function()
		expect(joinAsString(list, ", ")).toEqual("a, b, c")
	end)
end
