--!strict

--[[
	Button icon hint to show the player what gamepad button to press.
	Automatically becomes visible during gamepad input, and hides itself on non-gamepad input.
	TODO: Animate icon on pressed?
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InputCategorizer = require(ReplicatedStorage.Source.InputCategorizer)
local InputCategory = require(ReplicatedStorage.Source.SharedConstants.InputCategory)
local Signal = require(ReplicatedStorage.Source.Signal)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local prefabInstance: Frame = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "GamepadInputIconPrefab")

local GamepadButtonPrompt = {}
GamepadButtonPrompt.__index = GamepadButtonPrompt

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Frame,
		_isEnabled: boolean,
		_shouldBeVisible: boolean,
		_inputTypeChangedConnection: Signal.SignalConnection?,
	},
	GamepadButtonPrompt
))

function GamepadButtonPrompt.new(keyCode: Enum.KeyCode): ClassType
	local self = {
		_instance = prefabInstance:Clone() :: Frame,
		_inputTypeChangedConnection = nil,
		_isEnabled = true,
		_shouldBeVisible = false,
	}
	setmetatable(self, GamepadButtonPrompt)

	self:_setup(keyCode)

	return self
end

function GamepadButtonPrompt.setParent(self: ClassType, parent: Instance)
	self._instance.Parent = parent
end

function GamepadButtonPrompt._setup(self: ClassType, keyCode: Enum.KeyCode)
	self:_setIcon(keyCode)
	self:_listenForInputChanged()
end

function GamepadButtonPrompt._setIcon(self: ClassType, keyCode: Enum.KeyCode)
	local imageLabel: ImageLabel = getInstance(self._instance, "ImageLabel")
	imageLabel.Image = UserInputService:GetImageForKeyCode(keyCode)
end

function GamepadButtonPrompt._listenForInputChanged(self: ClassType)
	self:_onInput(InputCategorizer.getLast())
	self._inputTypeChangedConnection = InputCategorizer.changed:Connect(function(inputCategory: any?)
		self:_onInput(inputCategory :: InputCategory.EnumType)
	end)
end

function GamepadButtonPrompt._onInput(self: ClassType, inputCategory: InputCategory.EnumType)
	if inputCategory == InputCategory.Gamepad then
		self:_onGamepadInput()
	else
		self:_onNonGamepadInput()
	end
end

function GamepadButtonPrompt._updateVisibility(self: ClassType)
	self._instance.Visible = self._shouldBeVisible and self._isEnabled
end

function GamepadButtonPrompt._onGamepadInput(self: ClassType)
	self._shouldBeVisible = true
	self:_updateVisibility()
end

function GamepadButtonPrompt._onNonGamepadInput(self: ClassType)
	self._shouldBeVisible = false
	self:_updateVisibility()
end

function GamepadButtonPrompt._setVisible(self: ClassType, isVisible: boolean)
	self._instance.Visible = isVisible
end

function GamepadButtonPrompt.setEnabled(self: ClassType, isEnabled: boolean)
	self._isEnabled = isEnabled
	self:_updateVisibility()
end

function GamepadButtonPrompt.destroy(self: ClassType)
	local connection = self._inputTypeChangedConnection :: Signal.SignalConnection
	connection:Disconnect()
	self._instance:Destroy()
end

return GamepadButtonPrompt
