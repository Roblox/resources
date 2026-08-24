--!strict
local max = require(script.Parent.max)

return function()
	local dictionary = { a = 1, b = 2, c = 3 }
	it("default comparator", function()
		local resultValue, resultKey = max(dictionary)
		expect(resultKey).toEqual("c")
		expect(resultValue).toEqual(3)
	end)

	it("max, object", function()
		type person = { age: number }
		local child = { age = 5 }
		local teen = { age = 15 }
		local adult = { age = 25 }
		local people: { [string]: person } = { alice = child, bertram = teen, charlie = adult }

		local resultValue, resultKey = max(people, function(personA, personB)
			return personA.age > personB.age
		end)

		expect(resultKey).toEqual("charlie")
		expect(resultValue).toEqual(adult)
	end)

	it("max, empty", function()
		local value, key = max({})

		expect(value).toEqual(nil)
		expect(key).toEqual(nil)
	end)
end
