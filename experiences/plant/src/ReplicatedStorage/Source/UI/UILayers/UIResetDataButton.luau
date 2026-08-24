--!strict

--[[
	A button to reset player's data and restart the game.
	The button must be pressed twice to activate, due to the potential accidental data erasure if accidentally activated.
	Note: Not compatible with mobile (due to the double-press requirement without unhovering between), this is a studio-only feature.

	This is a singleton that can not be 'stopped' so we do not need to store connections to disconnect later.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local Button = require(ReplicatedStorage.Source.UI.UIComponents.Button)
local GamepadButtonPrompt = require(ReplicatedStorage.Source.UI.UIComponents.GamepadButtonPrompt)
local Keybind = require(ReplicatedStorage.Source.SharedConstants.Keybind)
local ColorTheme = require(ReplicatedStorage.Source.SharedConstants.ColorTheme)
local Network = require(ReplicatedStorage.Source.Network)
local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local RemoteEvents = Network.RemoteEvents

local LAYER_ID: UILayerId.EnumType = UILayerId.ResetDataButton
local HOVER_SIZE_SCALAR = 1.2
local CONFIRM_SIZE_SCALAR = 1.4
local SHAKE_DEGREES = 1
local SHAKE_DEGREES_PER_FRAME = 0.5
local CONFIRM_SHAKE_DEGREES = 3
local CONFIRM_SHAKE_DEGREES_PER_FRAME = 3
local HOVER_TWEEN_INFO = TweenInfo.new(0.2)
local SHORTCUT_UNHOVER_AFTER_SECONDS = 3 -- If activated by shortcut, we can't depend on a mouse to unhover to reset state. Manually unhover after time instead
local KEYCODE_BINDING_INFO: Button.KeyCodeBindingInfo = {
	actionName = "ResetData",
	keyCodes = {
		Keybind.GamepadResetDataButton,
		Keybind.KeyboardResetDataButton,
	},
}

local localPlayer = Players.LocalPlayer :: Player
local characterLoadedWrapper = CharacterLoadedWrapper.new(localPlayer)
local resetDataButtonPrefab: ScreenGui =
	getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "ResetDataButtonPrefab")
local instance = resetDataButtonPrefab:Clone()
local backgroundFrame: ImageLabel = getInstance(instance, "BackgroundFrame")
local contentFrame: Frame = getInstance(backgroundFrame, "ContentFrame")
local mainTextLabel: TextLabel = getInstance(contentFrame, "MainTextLabel")
local subTextLabel: TextLabel = getInstance(contentFrame, "SubTextLabel")
local originalSize = backgroundFrame.Size
local hoveredSize = UDim2.fromScale(originalSize.X.Scale * HOVER_SIZE_SCALAR, originalSize.Y.Scale * HOVER_SIZE_SCALAR)
local confirmSize =
	UDim2.fromScale(originalSize.X.Scale * CONFIRM_SIZE_SCALAR, originalSize.Y.Scale * CONFIRM_SIZE_SCALAR)
local originalMainText = mainTextLabel.Text
local originalSubText = subTextLabel.Text
local currentShakeDegrees = SHAKE_DEGREES
local currentShakeDegreesPerFrame = SHAKE_DEGREES_PER_FRAME

local UIResetDataButton = {}
UIResetDataButton._instance = instance
UIResetDataButton._button = Button.new(KEYCODE_BINDING_INFO)
UIResetDataButton._hoveredTween =
	TweenService:Create(backgroundFrame, HOVER_TWEEN_INFO, { Size = hoveredSize, BackgroundColor3 = ColorTheme.Red })
UIResetDataButton._confirmTween = TweenService:Create(
	backgroundFrame,
	HOVER_TWEEN_INFO,
	{ Size = confirmSize, BackgroundColor3 = ColorTheme.BrightRed }
)
UIResetDataButton._unhoveredTween = TweenService:Create(
	backgroundFrame,
	HOVER_TWEEN_INFO,
	{ Size = originalSize, Rotation = 0, BackgroundColor3 = ColorTheme.Gray }
)
UIResetDataButton._isHovered = false
UIResetDataButton._isConfirming = false
UIResetDataButton._isShaking = false
UIResetDataButton._lastInteractedTime = 0

function UIResetDataButton.setup(parent: Instance)
	UIResetDataButton._instance.Parent = parent
	UIResetDataButton._button:setParent(backgroundFrame)

	UIResetDataButton._setupButton()
	UIResetDataButton._registerLayer()
end

function UIResetDataButton.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

function UIResetDataButton.getInstance()
	return UIResetDataButton._instance
end

function UIResetDataButton._registerLayer()
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.HeadsUpDisplay, UIResetDataButton)

	visibilityChanged:Connect(function(isVisible: any)
		UIResetDataButton._button:setEnabled(isVisible :: boolean)
		UIResetDataButton._instance.Enabled = isVisible :: boolean
	end)

	UIHandler.show(LAYER_ID)
end

function UIResetDataButton._setupButton()
	UIResetDataButton._button:setSelectable(false)

	local gamepadButtonPrompt = GamepadButtonPrompt.new(Keybind.GamepadResetDataButton)
	gamepadButtonPrompt:setParent(backgroundFrame)

	UIResetDataButton._button.hovered:Connect(function(isHovering: any)
		UIResetDataButton._lastInteractedTime = DateTime.now().UnixTimestampMillis
		if isHovering :: boolean then
			UIResetDataButton._onHovered()
		else
			UIResetDataButton._resetButton()
		end
	end)

	UIResetDataButton._button.activated:Connect(UIResetDataButton._onActivated)
end

function UIResetDataButton._onActivated()
	UIResetDataButton._lastInteractedTime = DateTime.now().UnixTimestampMillis
	if UIResetDataButton._isConfirming then
		-- Activated during confirm
		UIResetDataButton._resetButton()
		UIHandler.hide(LAYER_ID)
		Network.fireServer(RemoteEvents.ResetData)
		characterLoadedWrapper.loaded:Wait()
		UIHandler.show(LAYER_ID)
	else
		-- Activated during default or hover state
		UIResetDataButton._confirmTween:Play()
		UIResetDataButton._isConfirming = true
		mainTextLabel.Text = PlayerFacingString.ResetDataButton.Confirm
		subTextLabel.Text = PlayerFacingString.ResetDataButton.ConfirmSubText
		currentShakeDegrees = CONFIRM_SHAKE_DEGREES
		currentShakeDegreesPerFrame = CONFIRM_SHAKE_DEGREES_PER_FRAME
		if not UIResetDataButton._isHovered then
			-- Activated via shortcut
			local thisLastInteracted = UIResetDataButton._lastInteractedTime
			UIResetDataButton._playShakingAnimation()
			task.delay(SHORTCUT_UNHOVER_AFTER_SECONDS, function()
				if thisLastInteracted == UIResetDataButton._lastInteractedTime then
					UIResetDataButton._resetButton()
				end
			end)
		end
	end
end

function UIResetDataButton._onHovered()
	if UIResetDataButton._isHovered then
		return
	end
	UIResetDataButton._isHovered = true

	if not UIResetDataButton._isConfirming then
		UIResetDataButton._hoveredTween:Play()
		UIResetDataButton._playShakingAnimation()
	end
end

function UIResetDataButton._playShakingAnimation()
	if UIResetDataButton._isShaking then
		return
	end
	UIResetDataButton._isShaking = true

	local rotationDegrees = 0
	local isIncreasing = true
	task.spawn(function()
		while UIResetDataButton._isHovered or UIResetDataButton._isConfirming do
			if isIncreasing then
				rotationDegrees += currentShakeDegreesPerFrame
				if rotationDegrees > currentShakeDegrees then
					rotationDegrees = currentShakeDegrees - 1
					isIncreasing = false
				end
			else
				rotationDegrees -= currentShakeDegreesPerFrame
				if rotationDegrees < -currentShakeDegrees then
					rotationDegrees = -currentShakeDegrees + 1
					isIncreasing = true
				end
			end
			local clampedRotation = math.clamp(rotationDegrees, -SHAKE_DEGREES, SHAKE_DEGREES)
			backgroundFrame.Rotation = clampedRotation
			contentFrame.Rotation = -clampedRotation
			task.wait()
		end
		UIResetDataButton._isShaking = false
	end)
end

function UIResetDataButton._resetButton()
	currentShakeDegrees = SHAKE_DEGREES
	currentShakeDegreesPerFrame = SHAKE_DEGREES_PER_FRAME
	backgroundFrame.Rotation = 0
	contentFrame.Rotation = 0
	UIResetDataButton._isConfirming = false
	UIResetDataButton._isHovered = false
	UIResetDataButton._unhoveredTween:Play()
	mainTextLabel.Text = originalMainText
	subTextLabel.Text = originalSubText
end

return UIResetDataButton
