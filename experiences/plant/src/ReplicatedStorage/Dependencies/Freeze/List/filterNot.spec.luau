--!strict
local filterNot = require(script.Parent.filterNot)

return function()
	local list = { 1, 2, 3, 4 }
	it("filterNot even", function()
		expect(filterNot(list, function(value)
			return value % 2 == 0
		end)).toEqual({ 1, 3 })
	end)
end
