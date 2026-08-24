--!strict
local every = require(script.Parent.every)

return function()
	local list = { "a", "b", "c" }
	it("match", function()
		expect(every(list, function(value)
			return type(value) == "string"
		end)).toEqual(true)
	end)

	it("no match", function()
		expect(every(list, function(value)
			return value == "b"
		end)).toEqual(false)
	end)

	it("none match", function()
		expect(every(list, function(value)
			return value == string.upper(value)
		end)).toEqual(false)
	end)
end
