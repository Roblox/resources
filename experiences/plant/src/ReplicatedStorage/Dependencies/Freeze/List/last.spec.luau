--!strict
local last = require(script.Parent.last)

return function()
	local list = { "a", "b", "c" }
	it("last", function()
		expect(last(list)).toEqual("c")
	end)

	it("default", function()
		expect(last({}, "default")).toEqual("default")
	end)
end
