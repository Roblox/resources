--!strict
local values = require(script.Parent.values)

return function()
	local dictionary = { a = 1 }
	it("values", function()
		expect(values(dictionary)).toEqual({ 1 })
	end)
end
