--!strict
local findIndex = require(script.Parent.findIndex)

return function()
	local list = { "a", "B", "c" }
	it("findIndex match", function()
		local result = findIndex(list, function(value)
			return string.upper(value) == value
		end)

		expect(result).toEqual(2)
	end)

	it("findIndex no match", function()
		local result = findIndex(list, function(value)
			return value == "d"
		end)

		expect(result).toEqual(nil)
	end)
end
