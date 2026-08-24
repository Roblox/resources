--!strict
local findPair = require(script.Parent.findPair)

return function()
	local list = { "a", "B", "c" }
	it("findPair match", function()
		local index, value = findPair(list, function(s)
			return string.upper(s) == s
		end)

		expect(index).toEqual(2)
		expect(value).toEqual("B")
	end)

	it("findPair no match", function()
		local index, value = findPair(list, function(s)
			return s == "d"
		end)

		expect(index).toEqual(nil)
		expect(value).toEqual(nil)
	end)
end
