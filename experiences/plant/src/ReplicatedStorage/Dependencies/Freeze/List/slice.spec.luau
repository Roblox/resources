--!strict
local slice = require(script.Parent.slice)

return function()
	local list = { "a", "b", "c" }
	it("no arguments", function()
		local result = slice(list)
		expect(result).toBe(list)
	end)

	it("positive from", function()
		local result = slice(list, 2)
		expect(result).toEqual({ "b", "c" })
	end)

	it("negative from", function()
		local result = slice(list, -1)
		expect(result).toEqual({ "c" })
	end)

	it("negative to", function()
		local result = slice(list, 1, -1)
		expect(result).toEqual({ "a", "b" })
	end)
end
