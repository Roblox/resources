--!strict
local has = require(script.Parent.has)

return function()
	local list = { "a", "b", "c" }
	it("exists", function()
		expect(has(list, 1)).toEqual(true)
	end)

	it("doesnt exist", function()
		expect(has(list, 4)).toEqual(false)
	end)
end
