--!strict
local first = require(script.Parent.first)

return function()
	local list = { "a", "b", "c" }
	it("first", function()
		expect(first(list)).toEqual("a")
	end)

	it("default", function()
		expect(first({}, "default")).toEqual("default")
	end)
end
