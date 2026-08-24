--!strict
local keys = require(script.Parent.keys)

return function()
	local dictionary = { a = 1 }
	it("keys", function()
		expect(keys(dictionary)).toEqual({ "a" })
	end)
end
