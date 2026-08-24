--!strict
local min = require(script.Parent.min)

return function()
	local dictionary = { a = 1, b = 2, c = 3 }
	it("default comparator", function()
		local resultValue, resultKey = min(dictionary)
		expect(resultKey).toEqual("a")
		expect(resultValue).toEqual(1)
	end)

	it("min, object", function()
		type person = { age: number }
		local child = { age = 5 }
		local teen = { age = 15 }
		local adult = { age = 25 }
		local people: { [string]: person } = { alice = child, bertram = teen, charlie = adult }

		local resultValue, resultKey = min(people, function(personA, personB)
			return personA.age > personB.age
		end)

		expect(resultKey).toEqual("alice")
		expect(resultValue).toEqual(child)
	end)

	it("min, empty", function()
		local value, key = min({})

		expect(value).toEqual(nil)
		expect(key).toEqual(nil)
	end)
end
