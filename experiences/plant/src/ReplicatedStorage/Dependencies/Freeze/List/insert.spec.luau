--!strict
local insert = require(script.Parent.insert)

return function()
	local list = { "a", "b", "c" }
	it("should insert 1 value", function()
		expect(insert(list, 2, "d")).toEqual({ "a", "d", "b", "c" })
	end)

	it("should insert multiple values", function()
		local result = insert({ "a", "b", "c" }, 2, "X", "Y", "Z")
		expect(result).toEqual({ "a", "X", "Y", "Z", "b", "c" })
	end)

	it("should insert and clamp 1 value out of bounds positive", function()
		local result = insert(list, 100, "d")
		expect(result).toEqual({ "a", "b", "c", "d" })
	end)

	it("should insert and clamp 1 value out of bounds negative", function()
		local result = insert(list, -100, "d")
		expect(result).toEqual({ "d", "a", "b", "c" })
	end)
end
