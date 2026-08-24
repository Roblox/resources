--!strict
local find = require(script.Parent.find)

return function()
	local list = { "a", "B", "c" }
	it("find match", function()
		local result = find(list, function(value)
			return string.upper(value) == value
		end)

		expect(result).toEqual("B")
	end)

	it("find no match", function()
		local result = find(list, function(value)
			return value == "d"
		end)

		expect(result).toEqual(nil)
	end)

	it("find no match, default value", function()
		local result = find(list, function(value)
			return value == "d"
		end, "default")

		expect(result).toEqual("default")
	end)
end
