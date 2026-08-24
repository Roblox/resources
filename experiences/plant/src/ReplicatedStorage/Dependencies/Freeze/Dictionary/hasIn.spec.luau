--!strict
local hasIn = require(script.Parent.hasIn)

return function()
	local dictionary = { a = { b = "c" } }
	it("should find existing index", function()
		local result = hasIn(dictionary, { "a", "b" })
		expect(result).toEqual(true)
	end)

	it("should return false for non-existing index", function()
		expect(hasIn(dictionary, { "d" })).toEqual(false)
	end)
end
