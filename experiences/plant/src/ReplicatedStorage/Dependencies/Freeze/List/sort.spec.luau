--!strict
local sort = require(script.Parent.sort)

return function()
	local list = { 4, 2, 3, 1 }
	it("no arguments", function()
		local result = sort(list)
		expect(result).toEqual({ 1, 2, 3, 4 })
	end)

	it("custom predicate", function()
		local result = sort(list, function(a, b)
			return a > b
		end)
		expect(result).toEqual({ 4, 3, 2, 1 })
	end)
end
