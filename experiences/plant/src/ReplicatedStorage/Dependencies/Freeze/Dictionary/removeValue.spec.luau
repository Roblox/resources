--!strict
local removeValue = require(script.Parent.removeValue)

return function()
	it("removeValue 1", function()
		local dictionary = { a = 1, b = 2, c = 3 }
		expect(removeValue(dictionary, 1)).toEqual({ b = 2, c = 3 })
	end)

	it("removeValue 2", function()
		local dictionary = { a = 1, b = 1, c = 3 }
		expect(removeValue(dictionary, 1)).toEqual({ c = 3 })
	end)

	it("removeValue 0, same id", function()
		local dictionary = { a = 1, b = 2, c = 3 }
		expect(removeValue(dictionary, 0)).toBe(dictionary)
	end)
end
