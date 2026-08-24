--!strict
local update = require(script.Parent.update)

return function()
	local list = { "a", "b", "c" }
	it("should replace existing index", function()
		local result = update(list, 1, function(value)
			assert(value, "exists")
			return string.rep(value, 5)
		end)

		expect(result).toEqual({ "aaaaa", "b", "c" })
	end)

	it("should pass nil to updater for nil index", function()
		local didReturn, returnedValue = false, nil
		local result = update(list, 4, function(_value)
			didReturn = true
			return "d"
		end)

		expect(didReturn).toEqual(true)
		expect(returnedValue).toEqual(nil)
		expect(result).toEqual({ "a", "b", "c", "d" })
	end)

	it("should pass notSetValue to updater for nil index", function()
		local result = update(list, 4, function(value)
			assert(value, "exists")
			return string.rep(value, 5)
		end, "d")

		expect(result).toEqual({ "a", "b", "c", "ddddd" })
	end)
end
