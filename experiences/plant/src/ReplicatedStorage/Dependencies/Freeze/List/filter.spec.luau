--!strict
local filter = require(script.Parent.filter)

return function()
	local list = { 1, 2, 3, 4 }
	it("filter even", function()
		expect(filter(list, function(value)
			return value % 2 == 0
		end)).toEqual({ 2, 4 })
	end)
end
