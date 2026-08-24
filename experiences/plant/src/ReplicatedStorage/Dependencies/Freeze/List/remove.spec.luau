--!strict
local remove = require(script.Parent:FindFirstChild("remove"))

return function()
	local list = { 10, 20, 30 }
	it("remove", function()
		local result = remove(list, 2)
		expect(result).toEqual({ 10, 30 })
	end)

	it("remove from end", function()
		local result = remove(list, -1)
		expect(result).toEqual({ 10, 20 })
	end)

	it("remove from end 2", function()
		local result = remove(list, -3)
		expect(result).toEqual({ 20, 30 })
	end)

	it("remove out of bounds, same id", function()
		local result = remove(list, 4)
		expect(result).toBe(list)
	end)

	it("remove multiple indicies", function()
		local result = remove(list, 1, 2)
		expect(result).toEqual({ 30 })
	end)

	it("remove multiple negative indicies, preserves order", function()
		local longList = { 1, 2, 3, 4, 5, 6, 7, 8 }
		local result = remove(longList, 8, -1) --removes the same value twice
		expect(result).toEqual({ 1, 2, 3, 4, 5, 6, 7 })
	end)

	it("remove multiple indicies, same id if no match", function()
		local longList = { 1, 2, 3, 4, 5, 6, 7, 8 }
		local result = remove(longList, 100, 200, -100)
		expect(result).toBe(longList)
	end)
end
