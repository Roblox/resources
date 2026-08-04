--!strict

--[[
	The InputCategorizer module categorizes various UserInputTypes (MouseButton1, MouseButton2, Gamepad1/2/3, etc.)
	into more manageable categories and provides an event for when the last input category changes, rather than last UserInputType.
--]]

local InputCategorizer = require(script.Parent.Parent.InputCategorizer)

local function onLastInputCategoryChanged(inputCategory)
	print(string.format("The input category has changed to %s!", inputCategory :: string))
end

InputCategorizer.lastInputCategoryChanged:Connect(onLastInputCategoryChanged)

local lastInputCategory = InputCategorizer.getLastInputCategory()
print(string.format("The current input category is %s!", lastInputCategory))
