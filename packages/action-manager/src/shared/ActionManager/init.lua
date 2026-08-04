--!strict

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local InputCategorizer = require(script.InputCategorizer)
local InputMetadata = require(script.InputMetadata)

local player = Players.LocalPlayer :: Player
local playerGui = player:WaitForChild("PlayerGui")
local instances = script.Instances :: any
local actionGui = instances.ActionGui

local HORIZONTAL_PADDING = 40
local VERTICAL_PADDING = 40

type ActionCallback = (string, Enum.UserInputState, InputObject) -> ...any

local InputCategory = {
	KeyboardAndMouse = "KeyboardAndMouse",
	Gamepad = "Gamepad",
	Touch = "Touch",
	Unknown = "Unknown",
}

local ActionManager = {
	InputCategory = InputCategory,
	_initialized = false,
	_bindings = {} :: { [string]: any },
}

function ActionManager.bindAction(
	actionName: string,
	callback: ActionCallback,
	keyboardAndMouseInput: Enum.KeyCode | Enum.UserInputType,
	gamepadInput: Enum.KeyCode | Enum.UserInputType,
	displayOrder: number?
)
	-- Make sure action binds aren't overwritten
	if ActionManager._bindings[actionName] then
		warn(string.format("'%s' is already bound!", actionName))
		return
	end

	local binding = {
		connections = {},
		keyboardAndMouseInput = keyboardAndMouseInput,
		gamepadInput = gamepadInput,
	}

	-- Create a new UI element
	local actionFrame = instances.ActionFrame:Clone()
	actionFrame.ContentFrame.ActionLabel.Text = actionName
	actionFrame.LayoutOrder = displayOrder or 0
	actionFrame.Parent = actionGui.ListFrame

	binding.frame = actionFrame
	ActionManager._updateInputDisplay(binding, InputCategorizer.getLastInputCategory())

	-- Create a wrapper for the callback function so the UI can be updated in sync with the action
	local callbackWrapper = function(...)
		local action, inputState = ...

		if action == actionName then
			if inputState == Enum.UserInputState.Begin then
				actionFrame.ContentFrame.ActionLabel.BackgroundColor3 = Color3.new(1, 1, 1)
				actionFrame.ContentFrame.ActionLabel.TextColor3 = Color3.new(0, 0, 0)
			elseif inputState == Enum.UserInputState.End then
				actionFrame.ContentFrame.ActionLabel.BackgroundColor3 = Color3.new(0, 0, 0)
				actionFrame.ContentFrame.ActionLabel.TextColor3 = Color3.new(1, 1, 1)
			end
		end

		callback(...)
	end

	-- Touch button connections
	table.insert(
		binding.connections,
		actionFrame.TouchButton.InputBegan:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.Touch then
				callbackWrapper(actionName, Enum.UserInputState.Begin, inputObject)
			end
		end)
	)

	table.insert(
		binding.connections,
		actionFrame.TouchButton.InputEnded:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.Touch then
				callbackWrapper(actionName, Enum.UserInputState.End, inputObject)
			end
		end)
	)

	-- Bind the action using ContextActionService
	ContextActionService:BindAction(actionName, callbackWrapper, false, keyboardAndMouseInput, gamepadInput)
	-- Save the binding
	ActionManager._bindings[actionName] = binding
end

function ActionManager.unbindAction(actionName: string)
	local binding = ActionManager._bindings[actionName]
	if binding then
		-- Disconnect all connections for the binding
		for _, connection in binding.connections do
			connection:Disconnect()
		end
		-- Destroy the UI element for the binding
		binding.frame:Destroy()
		ActionManager._bindings[actionName] = nil
	end

	-- Unbind the action from ContextActionService
	ContextActionService:UnbindAction(actionName)
end

function ActionManager._updateInputDisplay(binding, inputCategory)
	-- Remove old button display
	local oldButtonDisplay = binding.frame.ContentFrame.InputFrame:FindFirstChild("ButtonDisplayFrame")
	if oldButtonDisplay then
		oldButtonDisplay:Destroy()
	end

	-- Get a new button display
	local buttonDisplay: Instance
	if inputCategory == InputCategory.KeyboardAndMouse then
		buttonDisplay = ActionManager._getButtonDisplayForInput(binding.keyboardAndMouseInput)
	elseif inputCategory == InputCategory.Gamepad then
		buttonDisplay = ActionManager._getButtonDisplayForInput(binding.gamepadInput)
	elseif inputCategory == InputCategory.Touch then
		buttonDisplay = ActionManager._getButtonDisplayForInput(Enum.UserInputType.Touch)
	end
	buttonDisplay.Parent = binding.frame.ContentFrame.InputFrame

	-- Set the touch button to enabled/disabled depending on if the input category is touch
	binding.frame.TouchButton.Visible = inputCategory == InputCategory.Touch
end

-- Create a new button display frame based on the provided KeyCode or UserInputType
function ActionManager._getButtonDisplayForInput(input: Enum.KeyCode | Enum.UserInputType)
	local buttonDisplay = instances.ButtonDisplayFrame:Clone()
	local gamepadImage
	if input.EnumType == Enum.KeyCode then
		gamepadImage = UserInputService:GetImageForKeyCode(input :: Enum.KeyCode)
	end

	if input == Enum.UserInputType.Touch then
		local touchIcon = instances.TouchImageLabel:Clone()
		touchIcon.Parent = buttonDisplay
	elseif gamepadImage and gamepadImage ~= "" then
		local gamepadIcon = instances.GamepadImageLabel:Clone()
		gamepadIcon.Image = gamepadImage
		gamepadIcon.Parent = buttonDisplay
	elseif InputMetadata.MouseButtonImage[input] then
		local mouseIcon = instances.MouseImageLabel:Clone()
		mouseIcon.Image = InputMetadata.MouseButtonImage[input]
		mouseIcon.Parent = buttonDisplay
	else
		local border = instances.KeyboardBorderImage:Clone()
		border.Parent = buttonDisplay

		-- The following logic was taken and modified from the ProximityPrompt CoreScript
		-- UserInputService:GetStringForKeyCode() is used to display the correct input key when
		-- dealing with non-QWERTY keyboards
		local buttonTextString = UserInputService:GetStringForKeyCode(input :: Enum.KeyCode)

		local buttonTextImage = InputMetadata.KeyboardButtonImage[input]
		if not buttonTextImage then
			buttonTextImage = InputMetadata.KeyboardButtonIconMapping[buttonTextString]
		end

		if not buttonTextImage then
			local keyCodeMappedText = InputMetadata.KeyCodeToTextMapping[input :: Enum.KeyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end

		if buttonTextImage then
			local keyboardIcon = instances.KeyboardImageLabel:Clone()
			keyboardIcon.Image = buttonTextImage
			keyboardIcon.Parent = buttonDisplay
		elseif buttonTextString and buttonTextString ~= "" then
			local keyboardText = instances.KeyboardTextLabel:Clone()
			keyboardText.Text = buttonTextString
			keyboardText.TextSize = InputMetadata.KeyCodeToFontSize[input :: Enum.KeyCode]
				or InputMetadata.DefaultFontSize
			keyboardText.Parent = buttonDisplay
		end
	end

	return buttonDisplay
end

-- Return an InputCategory based on the UserInputType
function ActionManager._getCategoryOfInputType(inputType: Enum.UserInputType)
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

-- Return a default input category based on the current peripherals
function ActionManager._getDefaultInputCategory()
	if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return InputCategory.KeyboardAndMouse
	elseif UserInputService.TouchEnabled then
		return InputCategory.Touch
	elseif UserInputService.GamepadEnabled then
		return InputCategory.Gamepad
	else
		return InputCategory.Unknown
	end
end

-- Update the position and scale of the actions list
function ActionManager._updatePositionAndScale()
	local touchControlsEnabled = playerGui:FindFirstChild("TouchGui") ~= nil
	-- This is the same calculation used by the TouchGui for sizing the jump button
	local minScreenSize = math.min(actionGui.AbsoluteSize.X, actionGui.AbsoluteSize.Y)
	local isSmallScreen = minScreenSize < 500

	local verticalPadding = VERTICAL_PADDING
	if touchControlsEnabled and InputCategorizer.getLastInputCategory() == InputCategory.Touch then
		-- Offset the vertical padding to account for the jump button
		-- Note that the jump button can be two sizes depending on if the screen is considered small or not
		verticalPadding += if isSmallScreen then 70 else 210
	end

	-- If the screen is considered 'small', scale the action list down
	actionGui.ListFrame.UIScale.Scale = if isSmallScreen then 0.85 else 1
	actionGui.ListFrame.Position = UDim2.new(1, -HORIZONTAL_PADDING, 1, -verticalPadding)
end

function ActionManager._initialize()
	assert(not ActionManager._initialized, "ActionManager already initialized!")
	assert(RunService:IsClient(), "ActionManager can only be used on the client!")

	-- Update the position and scale of the list if the TouchGui is added/removed
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" then
			ActionManager._updatePositionAndScale()
		end
	end)

	playerGui.ChildRemoved:Connect(function(child)
		if child.Name == "TouchGui" then
			ActionManager._updatePositionAndScale()
		end
	end)

	-- Update the displayed buttons when the input category changes
	InputCategorizer.lastInputCategoryChanged:Connect(function(inputCategory)
		for _, binding in ActionManager._bindings do
			ActionManager._updateInputDisplay(binding, inputCategory)
		end
	end)

	-- Update the position and scale of the list when the screen size changes or last input category changes
	actionGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(ActionManager._updatePositionAndScale)
	InputCategorizer.lastInputCategoryChanged:Connect(ActionManager._updatePositionAndScale)

	-- Parent the UI to the player gui and update its position and scale
	actionGui.Parent = playerGui
	ActionManager._updatePositionAndScale()

	ActionManager._initialized = true
end

ActionManager._initialize()

return ActionManager
