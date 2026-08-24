--!strict
local indexOf = require(script.Parent.indexOf)

return function()
	local list = { "a", "b", "c" }
	it("exists", function()
		expect(indexOf(list, "b")).toEqual(2)
	end)

	it("doesnt exist", function()
		expect(indexOf(list, "d")).toEqual(nil)
	end)
end
