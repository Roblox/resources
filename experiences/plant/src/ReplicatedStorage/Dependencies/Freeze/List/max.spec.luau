--!strict
local max = require(script.Parent.max)

return function()
	local list = { 10, 200, 30 }
	it("max, default", function()
		local value, key = max(list)
		expect(value).toEqual(200)
		expect(key).toEqual(2)
	end)

	it("max, object", function()
		local child = { age = 5 }
		local teen = { age = 15 }
		local adult = { age = 25 }

		local result = max({ child, teen, adult }, function(personA, personB)
			return personA.age > personB.age
		end)

		expect(result).toEqual(adult)
	end)

	it("max, empty", function()
		local value, key = max({})

		expect(value).toEqual(nil)
		expect(key).toEqual(nil)
	end)
end
