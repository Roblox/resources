--!strict
local joinAsString = require(script.Parent.joinAsString)

return function()
	local dictionary = { a = 1 }
	it("joinAsString", function()
		expect(joinAsString(dictionary)).toEqual("a=1")
	end)

	it("empty", function()
		expect(joinAsString({})).toEqual("")
	end)
end
