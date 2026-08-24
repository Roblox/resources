--!strict
local remove = require(script.Parent:FindFirstChild("remove"))

return function()
	local dictionary = { a = 1, b = 2, c = 3 }
	it("remove 1", function()
		expect(remove(dictionary, "a")).toEqual({ b = 2, c = 3 })
	end)

	it("remove 2", function()
		expect(remove(dictionary, "a", "b")).toEqual({ c = 3 })
	end)

	it("remove missing key, same id", function()
		local result = remove(dictionary, "z")
		expect(result).toBe(result)
	end)
end
