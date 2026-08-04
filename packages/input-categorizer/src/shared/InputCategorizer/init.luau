--!strict

local UserInputService = game:GetService("UserInputService")

local Signal = require(script.Signal)

type ActionCallback = (string, Enum.UserInputState, InputObject) -> ...any

local InputCategory = {
	KeyboardAndMouse = "KeyboardAndMouse",
	Gamepad = "Gamepad",
	Touch = "Touch",
	Unknown = "Unknown",
}

local InputCategorizer = {
	InputCategory = InputCategory,
	lastInputCategoryChanged = Signal.new(),
	_lastInputCategory = InputCategory.Unknown,
	_initialized = false,
}

-- Return the last input category
function InputCategorizer.getLastInputCategory()
	return InputCategorizer._lastInputCategory
end

-- If _lastInputCategory and inputCategory are different, set _lastInputCategory and fire lastInputCategoryChanged
function InputCategorizer._setLastInputCategory(inputCategory: string)
	if InputCategorizer._lastInputCategory ~= inputCategory then
		InputCategorizer._lastInputCategory = inputCategory
		InputCategorizer.lastInputCategoryChanged:Fire(inputCategory)
	end
end

-- Return an InputCategory based on the UserInputType
function InputCategorizer._getCategoryOfInputType(inputType: Enum.UserInputType)
	if string.find(inputType.Name, "Gamepad") then
		return InputCategory.Gamepad
	elseif inputType == Enum.UserInputType.Keyboard or string.find(inputType.Name, "Mouse") then
		return InputCategory.KeyboardAndMouse
	elseif inputType == Enum.UserInputType.Touch then
		return InputCategory.Touch
	else
		return InputCategory.Unknown
	end
end

function InputCategorizer._onInputTypeChanged(inputType: Enum.UserInputType)
	local inputCategory = InputCategorizer._getCategoryOfInputType(inputType)
	if inputCategory ~= InputCategory.Unknown then
		InputCategorizer._setLastInputCategory(inputCategory)
	end
end

-- Return a default input category based on the current peripherals
function InputCategorizer._getDefaultInputCategory()
	local lastInputType = UserInputService:GetLastInputType()
	local lastInputCategory = InputCategorizer._getCategoryOfInputType(lastInputType)

	if lastInputCategory ~= InputCategory.Unknown then
		return lastInputCategory
	end

	if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return InputCategory.KeyboardAndMouse
	elseif UserInputService.TouchEnabled then
		return InputCategory.Touch
	elseif UserInputService.GamepadEnabled then
		return InputCategory.Gamepad
	else
		warn("No input devices detected!")
		return InputCategory.Unknown
	end
end

function InputCategorizer._initialize()
	assert(not InputCategorizer._initialized, "InputCategorizer already initialized!")

	-- Update the last category when the last inputType changes
	UserInputService.LastInputTypeChanged:Connect(InputCategorizer._onInputTypeChanged)

	-- Set the starting input category
	local defaultInputCategory = InputCategorizer._getDefaultInputCategory()
	InputCategorizer._setLastInputCategory(defaultInputCategory)

	InputCategorizer._initialized = true
end

InputCategorizer._initialize()

return InputCategorizer
