--!strict
local removeIn = require(script.Parent:FindFirstChild("removeIn"))

return function()
	local dictionary = { a = { b = { "c" } } }
	it("removeIn 1", function()
		expect(removeIn(dictionary, { "a" })).toEqual({})
	end)

	it("removeIn 2", function()
		expect(removeIn(dictionary, { "a", "b" })).toEqual({ a = {} })
	end)

	it("removeIn 3", function()
		expect(removeIn(dictionary, { "a", "b", "c" })).toEqual({ a = { b = { "c" } } })
	end)

	it("removeIn 4", function()
		expect(removeIn(dictionary, { "x", "y", "z" })).toEqual({ a = { b = { "c" } }, x = { y = {} } })
	end)
end
