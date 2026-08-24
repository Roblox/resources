--!strict
local flip = require(script.Parent.flip)

return function()
	local dictionary: { [string]: string } = { a = "A", b = "B", c = "C" }
	it("flip match", function()
		local result = flip(dictionary)

		expect(result).toEqual({ A = "a", B = "b", C = "c" })
	end)
end
