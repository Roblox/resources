--!strict
local get = require(script.Parent.get)

return function()
	local list = { "a", "b", "c" }
	it("should find existing index", function()
		expect(get(list, 1)).toEqual("a")
	end)

	it("should return nil for non-existing index", function()
		expect(get(list, 4)).toEqual(nil)
	end)

	it("should return default for non-existing index", function()
		expect(get(list, 4, "d")).toEqual("d")
	end)

	it("should handle negative index", function()
		expect(get(list, -1)).toEqual("c")
	end)

	it("should handle negative index out of bounds", function()
		expect(get(list, -100)).toEqual(nil)
	end)
end
