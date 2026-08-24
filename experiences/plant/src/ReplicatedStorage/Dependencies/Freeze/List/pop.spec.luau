--!strict
local pop = require(script.Parent.pop)

return function()
	local list = { 10, 20, 30 }
	it("pop, default", function()
		local result = pop(list)
		expect(result).toEqual({ 10, 20 })
	end)

	it("pop, 2", function()
		local result = pop(list, 2)
		expect(result).toEqual({ 10 })
	end)

	it("pop, empty", function()
		local empty = {}
		local result = pop(empty)

		expect(result).toEqual({})
	end)
end
