--!strict
local skip = require(script.Parent.skip)

return function()
	local list = { "a", "b", "c" }
	it("skip 1", function()
		expect(skip(list, 1)).toEqual({ "b", "c" })
	end)

	it("skip 2", function()
		expect(skip(list, 2)).toEqual({ "c" })
	end)
end
