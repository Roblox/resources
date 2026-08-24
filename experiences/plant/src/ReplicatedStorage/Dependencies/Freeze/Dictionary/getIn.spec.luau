--!strict
local getIn = require(script.Parent.getIn)

return function()
	local dictionary = { a = { b = "c" } }
	it("should find existing index", function()
		local result = getIn(dictionary, { "a", "b" })
		expect(result).toEqual("c")
	end)

	it("should return nil for non-existing index", function()
		local result = getIn(dictionary, { "a", "b", "c" })
		expect(result).toEqual(nil)
	end)

	it("should return nil for non-existing index 2", function()
		local result = getIn(dictionary, { "x", "y", "z" })
		expect(result).toEqual(nil)
	end)

	it("should return default for non-existing index", function()
		expect(getIn(dictionary, { "d" }, "default")).toEqual("default")
	end)
end
