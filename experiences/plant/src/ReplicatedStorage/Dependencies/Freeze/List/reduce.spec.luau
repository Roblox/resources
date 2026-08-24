--!strict
local reduce = require(script.Parent.reduce)

return function()
	local list = { 10, 20, 30 }
	it("reduce", function()
		local result = reduce(list, function(reduction: number, value)
			return reduction + value
		end, 0)

		expect(result).toEqual(60)
	end)

	it("order left to right", function()
		local result = reduce(list, function(reduction: string, value)
			return reduction .. tostring(value)
		end, "")

		expect(result).toEqual("102030")
	end)
end
