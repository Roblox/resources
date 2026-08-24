--!strict
local set = require(script.Parent.set)

return function()
	local list = { "a", "b", "c" }
	it("should replace existing index", function()
		expect(set(list, 1, "A")).toEqual({ "A", "b", "c" })
	end)

	it("should add new index", function()
		expect(set(list, 4, "D")).toEqual({ "a", "b", "c", "D" })
	end)

	it("should add new index out of bounds", function()
		expect(set(list, 6, "D")).toEqual({ "a", "b", "c", nil, nil, "D" } :: { string? })
	end)
end
