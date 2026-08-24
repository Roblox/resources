--!strict
local has = require(script.Parent.has)

return function()
	local dictionary: { [string]: number } = { a = 1, b = 2, c = 3 }
	it("should find existing index", function()
		local result = has(dictionary, "a")
		expect(result).toEqual(true)
	end)

	it("should return false for non-existing index", function()
		expect(has(dictionary, "d")).toEqual(false)
	end)
end
