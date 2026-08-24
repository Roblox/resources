--!strict
local includes = require(script.Parent.includes)

return function()
	local list = { "a", "b", "c" }
	it("exists", function()
		expect(includes(list, "b")).toEqual(true)
	end)

	it("doesnt exist", function()
		expect(includes(list, "d")).toEqual(false)
	end)
end
