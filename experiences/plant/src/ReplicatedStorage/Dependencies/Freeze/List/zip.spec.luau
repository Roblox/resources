--!strict
local zip = require(script.Parent.zip)

return function()
	local list = { "a", "b", "c" }
	it("matching lengths", function()
		local result = zip(list, { "x", "y", "z" })

		expect(result).toEqual({ { "a", "x" }, { "b", "y" }, { "c", "z" } })
	end)

	it("mismatching lengths", function()
		local result = zip(list, {
			"x",
			"y",
			"z",
			"W", --will be dropped
		})

		expect(result).toEqual({ { "a", "x" }, { "b", "y" }, { "c", "z" } })
	end)
end
