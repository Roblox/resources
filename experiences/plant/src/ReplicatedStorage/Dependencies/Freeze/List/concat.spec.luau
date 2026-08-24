--!strict
local concat = require(script.Parent.concat)

return function()
	local list = { "a", "b", "c" }
	it("concat 2 values", function()
		local result = concat(list, { "x", "y", "z" })
		expect(result).toEqual({ "a", "b", "c", "x", "y", "z" })
	end)

	it("concat 3 values", function()
		local result = concat(list, { "x", "y", "z" }, list)
		expect(result).toEqual({ "a", "b", "c", "x", "y", "z", "a", "b", "c" })
	end)

	it("concat 1 value", function()
		local result = concat(list)
		expect(result).toEqual({ "a", "b", "c" })
	end)

	it("handle nil", function()
		local result = concat(list, nil, { "x", "y", "z" })

		expect(result).toEqual({ "a", "b", "c", "x", "y", "z" })
	end)

	it("handle empty table", function()
		local result = concat(list, {}, { "x", "y", "z" })
		expect(result).toEqual({ "a", "b", "c", "x", "y", "z" })
	end)

	it("handle objects", function()
		local youngList = { { age = 0 } }
		local oldList = { { age = 100 } }
		local result = concat(youngList, oldList)
		expect(result).toEqual({ { age = 0 }, { age = 100 } })
	end)
end
