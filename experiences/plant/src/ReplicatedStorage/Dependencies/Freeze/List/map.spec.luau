--!strict
local map = require(script.Parent.map)

return function()
	local list = { "a", "b", "c" }
	it("map", function()
		local result = map(list, string.upper)
		expect(result).toEqual({ "A", "B", "C" })
	end)

	it("map, filter", function()
		local result = map(list, function(value)
			return if value == "c" then nil else string.upper(value)
		end)

		expect(result).toEqual({ "A", "B" })
	end)

	it("map, change type", function()
		local result = map(list, function(_value)
			return 1
		end)

		expect(result).toEqual({ 1, 1, 1 })
	end)
end
