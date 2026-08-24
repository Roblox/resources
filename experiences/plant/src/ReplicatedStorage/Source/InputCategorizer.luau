--!strict

--[[
	This keeps track of the most recent "input category" that scripts can use to
	properly switch between touch, gamepad, and keyboard/mouse interfaces.

	This also provides a changed event and a getter for the last input category.

	An "input category" is a simplified grouping for UserInputTypes, defined below:
		1. Gamepad1 through Gamepad8 are just InputCategory.Gamepad
		2. Keyboard and Mouse input are both InputCategory.KeyboardMouse
		3. Touch is InputCategory.KeyboardMouse, a 1:1 translation
		4. Everything else is InputCategory.Other

	This is useful for easily comparing one input category string rather than checking
	against a whole list of UserInputTypes.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.Source.Signal)
local InputCategory = require(ReplicatedStorage.Source.SharedConstants.InputCategory)

-- Return a default input category based on the current peripherals
local function getDefaultInputType(): InputCategory.EnumType
	local defaultInputType: InputCategory.EnumType

	if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		defaultInputType = InputCategory.KeyboardMouse
	elseif UserInputService.TouchEnabled then
		defaultInputType = InputCategory.Touch
	elseif UserInputService.GamepadEnabled then
		defaultInputType = InputCategory.Gamepad
	end

	return defaultInputType
end

local InputCategorizer = {
	_activeInputType = getDefaultInputType(),
	changed = Signal.new(),
}

function InputCategorizer._setActiveInputCategory(inputCategory: InputCategory.EnumType)
	if InputCategorizer._activeInputType ~= inputCategory then
		InputCategorizer._activeInputType = inputCategory
		InputCategorizer.changed:Fire(InputCategorizer._activeInputType)
	end
end

function InputCategorizer._onInputTypeChanged(newInputType: Enum.UserInputType)
	local inputCategory: InputCategory.EnumType = InputCategorizer.getCategoryOf(newInputType)
	if inputCategory ~= InputCategory.Other then
		InputCategorizer._setActiveInputCategory(inputCategory)
	end
end

function InputCategorizer.getCategoryOf(userInputType: Enum.UserInputType): InputCategory.EnumType
	local inputCategory: InputCategory.EnumType

	if userInputType.Name:find("Gamepad") then
		-- Covers enum UserInputTypes of Gamepad1 .. Gamepad8
		inputCategory = InputCategory.Gamepad
	elseif userInputType == Enum.UserInputType.Keyboard or userInputType.Name:find("Mouse") then
		-- Covers enum UserInputTypes of Keyboard and MouseMovement, MouseWheel, and MouseButton1 .. MouseButton3
		inputCategory = InputCategory.KeyboardMouse
	elseif userInputType == Enum.UserInputType.Touch then
		inputCategory = InputCategory.Touch
	else
		inputCategory = InputCategory.Other
	end

	return inputCategory
end

function InputCategorizer.getLast(): InputCategory.EnumType
	return InputCategorizer._activeInputType
end

function InputCategorizer._setup()
	UserInputService.LastInputTypeChanged:Connect(function(...)
		InputCategorizer._onInputTypeChanged(...)
	end)
end

InputCategorizer._setup() --TODO: Reevaluate self launching services

return InputCategorizer
