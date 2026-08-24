--!strict
local setIn = require(script.Parent.setIn)

return function()
	local dictionary = { a = { b = { "c" } } }
	it("setIn 1", function()
		expect(setIn(dictionary, { "a" }, "test")).toEqual({ a = "test" })
	end)

	it("setIn 2", function()
		expect(setIn(dictionary, { "a", "b" }, "test")).toEqual({ a = { b = "test" } })
	end)

	it("setIn 3", function()
		expect(setIn(dictionary, { "a", "b", "c" }, "test")).toEqual({ a = { b = { "c", c = "test" } } })
	end)

	it("setIn 4", function()
		expect(setIn(dictionary, { "x", "y", "z" }, "test")).toEqual({ a = { b = { "c" } }, x = { y = { z = "test" } } })
	end)

	it("age", function()
		local ageTest = {
			persons = {
				alice = {
					age = 10,
				},
			},
		}
		local result = setIn(ageTest, { "persons", "alice", "age" }, 11)
		expect(result).toEqual({ persons = { alice = { age = 11 } } })
	end)
end
