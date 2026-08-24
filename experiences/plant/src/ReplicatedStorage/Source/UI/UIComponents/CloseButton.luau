--!strict

--[[
	Adds hovering animations and an "×" label with a button component
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GamepadButtonPrompt = require(script.Parent.GamepadButtonPrompt)
local Button = require(script.Parent.Button)
local Signal = require(ReplicatedStorage.Source.Signal)
local ColorTheme = require(ReplicatedStorage.Source.SharedConstants.ColorTheme)
local Keybind = require(ReplicatedStorage.Source.SharedConstants.Keybind)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local prefabInstance: Frame = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "CloseButtonFramePrefab")
local prefabTextLabel: TextLabel = getInstance(prefabInstance, "Contents", "TextLabel")

local CLOSE_TEXT_COLOR = prefabTextLabel.TextColor3
local CLOSE_TEXT_COLOR_HOVER = ColorTheme.White
local CLOSE_TEXT_COLOR_DISABLED = ColorTheme.Gray
local TWEEN_INFO = TweenInfo.new(0.1)

local keyCodeBindingInfo: Button.KeyCodeBindingInfo = {
	actionName = "ActivateCloseActionButton",
	keyCodes = {
		Keybind.GamepadBackAction,
		Keybind.KeyboardBackAction,
	},
}

local CloseButton = {}
CloseButton.__index = CloseButton

export type ClassType = typeof(setmetatable(
	{} :: {
		_button: Button.ClassType,
		_gamepadButtonPrompt: GamepadButtonPrompt.ClassType,
		_instance: Frame,
		_isEnabled: boolean,
		_hoveredConnection: Signal.SignalConnection?,
		_tweenIn: Tween?,
		_tweenOut: Tween?,
		_tweenDisabled: Tween?,
	},
	CloseButton
))

function CloseButton.new(): ClassType
	local instance = prefabInstance:Clone() :: Frame

	local self = {
		_button = Button.new(keyCodeBindingInfo),
		_gamepadButtonPrompt = GamepadButtonPrompt.new(Keybind.GamepadBackAction),
		_instance = instance,
		_isEnabled = true,
		_hoveredConnection = nil,
		_tweenIn = nil,
		_tweenOut = nil,
		_tweenDisabled = nil,
	}

	setmetatable(self, CloseButton)

	self:_setup()

	return self
end

function CloseButton.setParent(self: ClassType, parent: Instance)
	self._instance.Parent = parent
end

function CloseButton._setup(self: ClassType)
	self._button:setParent(self._instance)
	local contentsFrame: Frame = getInstance(self._instance, "Contents")
	self._gamepadButtonPrompt:setParent(contentsFrame)

	self:_setupTweens()
	self:_setupConnections()
	self._button:setSelectable(false)
end

function CloseButton.getButton(self: ClassType)
	return self._button
end

function CloseButton.getInstance(self: ClassType)
	return self._instance
end

function CloseButton._setupTweens(self: ClassType)
	local textLabel: TextLabel = getInstance(self._instance, "Contents", "TextLabel")

	self._tweenIn = TweenService:Create(textLabel, TWEEN_INFO, { TextColor3 = CLOSE_TEXT_COLOR_HOVER })
	self._tweenOut = TweenService:Create(textLabel, TWEEN_INFO, { TextColor3 = CLOSE_TEXT_COLOR })
	self._tweenDisabled = TweenService:Create(textLabel, TWEEN_INFO, { TextColor3 = CLOSE_TEXT_COLOR_DISABLED })
end

function CloseButton._setupConnections(self: ClassType)
	assert(
		self._tweenIn and self._tweenOut and self._tweenDisabled,
		"setupTweens must be called before setupConnections"
	)

	self._hoveredConnection = self._button.hovered:Connect(function(isHovering: any)
		if not self._isEnabled then
			return
		end

		if isHovering :: boolean then
			self._tweenIn:Play()
		else
			self._tweenOut:Play()
		end
	end)
end

function CloseButton.setEnabled(self: ClassType, isEnabled: boolean)
	self._isEnabled = isEnabled
	self._gamepadButtonPrompt:setEnabled(isEnabled)
	self._button:setEnabled(isEnabled)

	if isEnabled then
		local tweenOut = self._tweenOut :: Tween
		tweenOut:Play()
	else
		local tweenDisabled = self._tweenDisabled :: Tween
		tweenDisabled:Play()
	end
end

function CloseButton.destroy(self: ClassType)
	local hoveredConnection = self._hoveredConnection :: Signal.SignalConnection
	hoveredConnection:Disconnect()
	self._button:destroy()
	self._gamepadButtonPrompt:destroy()
	self._instance:Destroy()
end

return CloseButton
