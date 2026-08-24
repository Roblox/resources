--!strict
local findWhereLast = require(script.Parent.findWhereLast)

return function()
	local list = { "a", "B", "c" }
	it("find match", function()
		local result = findWhereLast(list, function(value)
			return true
		end)

		expect(result).toEqual("c")
	end)

	it("find no match", function()
		local result = findWhereLast(list, function(value)
			return value == "d"
		end)

		expect(result).toEqual(nil)
	end)

	it("find no match, default value", function()
		local result = findWhereLast(list, function(value)
			return value == "d"
		end)

		expect(result).toEqual(nil)
	end)
end
