--!strict
local mergeIn = require(script.Parent.mergeIn)

return function()
	it("mergeIn", function()
		local dictionary = {
			persons = {
				alice = {
					age = 10,
				},
			},
		}

		local result = mergeIn(dictionary, { "persons", "alice" }, { age = 11 })
		expect(result).toEqual({ persons = { alice = { age = 11 } } })
	end)
end
