--!strict
local min = require(script.Parent.min)

return function()
	local list = { 10, -200, 30 }
	it("min, default", function()
		local value, key = min(list)
		expect(value).toEqual(-200)
		expect(key).toEqual(2)
	end)

	it("min, object", function()
		local child = { age = 5 }
		local teen = { age = 15 }
		local adult = { age = 25 }

		local result = min({ child, teen, adult }, function(personA, personB)
			return personA.age > personB.age
		end)

		expect(result).toEqual(child)
	end)

	it("min, empty", function()
		local value, key = min({})

		expect(value).toEqual(nil)
		expect(key).toEqual(nil)
	end)
end
