--!strict
local updateIn = require(script.Parent.updateIn)

return function()
	local dictionary = {
		persons = {
			alice = {
				age = 10,
			},
		},
	}

	--
	it("should replace existing key", function()
		local result = updateIn(dictionary, { "persons", "alice", "age" }, function(value: number)
			assert(value, "will exist")
			return value + 1
		end)

		expect(result).toEqual({ persons = { alice = { age = 11 } } })
	end)

	it("should pass nil to updater for nil key", function()
		local didReturn, returnedValue = false, nil
		local result = updateIn(dictionary, { "persons", "alice", "age" }, function(_value)
			didReturn = true
			return 4
		end)

		expect(didReturn).toEqual(true)
		expect(returnedValue).toEqual(nil)
		expect(result).toEqual({ persons = { alice = { age = 4 } } })
	end)

	it("should pass notSetValue to updater for nil key", function()
		local result = updateIn(dictionary, { "persons", "alice", "test" }, function(value)
			assert(value, "exists")
			return value + 1
		end, 4)

		expect(result).toEqual({ persons = { alice = { age = 10, test = 5 } } })
	end)
end
