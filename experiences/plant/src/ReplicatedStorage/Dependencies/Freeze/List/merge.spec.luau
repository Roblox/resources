--!strict
local merge = require(script.Parent.merge)
local None = require(script.Parent.Parent.None)

return function()
	it("merge 2", function()
		local array: { string? } = { "a", nil, "c" }
		local other: { string? } = { nil, "b", "C" }
		local result = merge(array, other)

		expect(result).toEqual({ "a", "b", "C" })
	end)

	it("merge 3, with none", function()
		local result = merge({ "a", "b", "c" }, { "x" }, { nil, "y", None } :: { any })

		expect(result).toEqual({ "x", "y" })
	end)
end
