--!strict
local push = require(script.Parent.push)

return function()
	local list = { 10, 20 }
	it("push, 1", function()
		local result = push(list, 30)
		expect(result).toEqual({ 10, 20, 30 })
	end)

	it("push, 2", function()
		local result = push(list, 30, 40)
		expect(result).toEqual({ 10, 20, 30, 40 })
	end)

	it("push, 0", function()
		local result = push(list)
		expect(result).toBe(list)
	end)
end
