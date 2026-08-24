--!nonstrict
local isValueObject = require(script.Parent.isValueObject)

return function(valueA, valueB)
	if valueA == valueB or (valueA ~= valueA and valueB ~= valueB) then
		return true
	end

	if not valueA or not valueB then
		return false
	end

	if typeof(valueA) == "function" and typeof(valueB) == "function" then
		valueA = valueA()
		valueB = valueB()
		if valueA == valueB or (valueA ~= valueA and valueB ~= valueB) then
			return true
		end
		if not valueA or not valueB then
			return false
		end
	end

	return not not (isValueObject(valueA) and isValueObject(valueB) and valueA.equals(valueB))
end
