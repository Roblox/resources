--!strict
local includes = require(script.Parent.includes)

return function()
	local dictionary = { a = 1, b = 2, c = 3 }
	it("exists", function()
		expect(includes(dictionary, 2)).toEqual(true)
	end)

	it("doesnt exist", function()
		expect(includes(dictionary, 4)).toEqual(false)
	end)
end
