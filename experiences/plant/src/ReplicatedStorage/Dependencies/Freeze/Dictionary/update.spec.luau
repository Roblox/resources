--!strict
local update = require(script.Parent.update)

return function()
	local dictionary: { [string]: number } = { a = 1, b = 2, c = 3 }
	it("should replace existing key", function()
		local result = update(dictionary, "a", function(value)
			assert(value, "should exist")
			return value * 100
		end)

		expect(result).toEqual({ a = 100, b = 2, c = 3 })
	end)

	it("should pass nil to updater for nil key", function()
		local didReturn, returnedValue = false, nil
		local result = update(dictionary, "d", function(_value)
			didReturn = true
			return 4
		end)

		expect(didReturn).toEqual(true)
		expect(returnedValue).toEqual(nil)
		expect(result).toEqual({ a = 1, b = 2, c = 3, d = 4 })
	end)

	it("should pass notSetValue to updater for nil key", function()
		local result = update(dictionary, "d", function(value)
			assert(value, "exists")
			return value * 100
		end, 4)

		expect(result).toEqual({ a = 1, b = 2, c = 3, d = 400 })
	end)
end
