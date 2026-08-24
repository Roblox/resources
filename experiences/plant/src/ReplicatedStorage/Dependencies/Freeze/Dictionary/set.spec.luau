--!strict
local set = require(script.Parent.set)

return function()
	local dictionary = { a = 1, b = 2, c = 3 }
	it("set existing", function()
		expect(set(dictionary, "b", 4)).toEqual({ a = 1, b = 4, c = 3 })
	end)

	it("set new", function()
		expect(set(dictionary, "d", 4)).toEqual({ a = 1, b = 2, c = 3, d = 4 })
	end)

	it("set no change, same id", function()
		expect(set(dictionary, "a", 1)).toBe(dictionary)
	end)
end
