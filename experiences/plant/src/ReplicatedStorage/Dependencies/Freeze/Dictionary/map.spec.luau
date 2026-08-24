--!strict
local map = require(script.Parent.map)

return function()
	local dictionary: { [string]: number } = { a = 1, b = 2, c = 3 }
	it("map", function()
		local result = map(dictionary, function(value, key)
			return value * 10, key
		end)
		expect(result).toEqual({ a = 10, b = 20, c = 30 })
	end)

	it("change type", function()
		local result = map(dictionary, function(value, key)
			return tostring(value), key
		end)
		expect(result).toEqual({ a = "1", b = "2", c = "3" })
	end)

	it("filters with nil", function()
		local result = map(dictionary, function(value, key)
			return if value == 2 then nil else value, key
		end)
		expect(result).toEqual({ a = 1, c = 3 })
	end)

	it("convert list to dictionary", function()
		local list = { "a", "b", "c" }
		local result = map(list, function(_value)
			return 0, "a"
		end)
		expect(result).toEqual({ a = 0 })
	end)
end
