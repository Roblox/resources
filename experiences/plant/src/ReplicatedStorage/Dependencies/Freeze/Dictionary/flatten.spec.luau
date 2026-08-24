--!strict
local flatten = require(script.Parent.flatten)

return function()
	local dictionary = {
		foo = 1,
		foobar = {
			bar = 2,
			baz = {
				etc = 3,
			},
		},
	}

	it("flatten", function()
		local result = flatten(dictionary)

		expect(result).toEqual({ foo = 1, bar = 2, etc = 3 })
	end)

	it("flatten with depth", function()
		local result = flatten(dictionary, 1)

		expect(result).toEqual({ foo = 1, bar = 2, baz = { etc = 3 } })
	end)
end
