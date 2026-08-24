--!strict
local flatten = require(script.Parent.flatten)

return function()
	it("flatten, no depth, no change", function()
		local list = { "a", "B", "c" }
		local result = flatten(list)
		expect(result).toEqual({ "a", "B", "c" })
	end)

	it("flatten, depth of 1", function()
		local result = flatten({
			"foo",
			{
				"bar",
				"baz",
			},
			{
				"bar",
				"baz",
			},
			"quz",
		})

		expect(result).toEqual({ "foo", "bar", "baz", "bar", "baz", "quz" })
	end)

	local listDepth2: { any } = {
		"foo",
		{
			"bar",
			"baz",
			{
				"bar",
				"baz",
			},
		} :: { any },

		"quz",
	}
	it("flatten, depth of 2", function()
		local result = flatten(listDepth2)
		expect(result).toEqual({ "foo", "bar", "baz", "bar", "baz", "quz" })
	end)

	it("flatten, depth of 2, limit 1", function()
		local result = flatten(listDepth2, 1)
		expect(result).toEqual({ "foo", "bar", "baz", { "bar", "baz" }, "quz" } :: { any })
	end)
end
