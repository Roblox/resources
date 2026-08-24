--!strict
local merge = require(script.Parent.merge)

return function()
	local dictionary = { a = 1, b = 2, c = 3 }
	it("merge 2", function()
		local result = merge(dictionary, { x = 4, y = 5, z = 6 })
		expect(result).toEqual({ a = 1, b = 2, c = 3, x = 4, y = 5, z = 6 })
	end)

	it("merge 3 with overwrite", function()
		local result = merge(dictionary, { x = 4 }, { a = "test" })
		expect(result).toEqual({ a = "test", b = 2, c = 3, x = 4 })
	end)
end
