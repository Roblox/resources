--!strict
local Freeze = require(script.Parent)

return function()
	it("handle multiple operations", function()
		local list = { "a", "b" }
		local list2 = Freeze.List.push(list, "c")
		local list3 = Freeze.List.map(list2, function(value)
			return string.upper(value)
		end)
		expect(list3).toEqual({ "A", "B", "C" })
	end)

	it("deprecation warning", function()
		do
			local dictionary = { a = 1, b = 2, c = 3 }
			local result = Freeze.Dictionary.removeKeys(dictionary, "b", "c")
			expect(result).toEqual({ a = 1 })
		end

		do
			local list = { "a", "b", "c" }
			local result = Freeze.List.append(list, "b", "c")
			expect(result).toEqual({ "a", "b", "c", "b", "c" })
		end
	end)
end
