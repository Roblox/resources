--!strict
local reduceRight = require(script.Parent.reduceRight)

return function()
	local list = { 10, 20, 30 }
	it("reduceRight", function()
		local result = reduceRight(list, function(reduction: number, value)
			return reduction + value
		end, 0)

		expect(result).toEqual(60)
	end)

	it("order right to left", function()
		local result = reduceRight(list, function(reduction: string, value)
			return reduction .. tostring(value)
		end, "")

		expect(result).toEqual("302010")
	end)
end
