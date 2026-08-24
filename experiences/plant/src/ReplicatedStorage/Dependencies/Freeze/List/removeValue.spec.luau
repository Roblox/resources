--!strict
local removeValue = require(script.Parent.removeValue)

return function()
	local list = { 10, 20, 30 }
	local longerList = { 10, 20, 30, 10, 20, 30 }
	it("removeValue", function()
		local result = removeValue(list, 20)
		expect(result).toEqual({ 10, 30 })
	end)

	it("removeValue not found, keeps identity", function()
		local result = removeValue(list, 100)
		expect(result).toBe(list)
	end)

	it("removeValue for all repeated values", function()
		local result = removeValue(longerList, 20)
		expect(result).toEqual({ 10, 30, 10, 30 })
	end)

	it("removeValue multiple values", function()
		local result = removeValue(list, 20, 30)
		expect(result).toEqual({ 10 })
	end)

	it("removeValue multiple values, even if some arent there", function()
		local result = removeValue(list, 20, 30, 40)
		expect(result).toEqual({ 10 })
	end)

	it("removeValue multiple values, multiple times", function()
		local result = removeValue(longerList, 20, 30)
		expect(result).toEqual({ 10, 10 })
	end)
end
