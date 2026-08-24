--!strict
local get = require(script.Parent.get)

return function()
	local dictionary: { [string]: number } = { a = 1, b = 2, c = 3 }
	it("should find existing index", function()
		local result = get(dictionary, "a")
		expect(result).toEqual(1)
	end)

	it("should return nil for non-existing index", function()
		expect(get(dictionary, "d")).toEqual(nil)
	end)

	it("should return default for non-existing index", function()
		expect(get(dictionary, "d", 4)).toEqual(4)
	end)
end
