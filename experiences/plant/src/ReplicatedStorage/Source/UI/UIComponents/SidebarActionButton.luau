--!strict

--[[
	Adds hovering and disabled animations with a Frame and TextLabel meant to be
	used on a ListSelector Sidebar component. Includes a button component.

	Exposes functionality to set the button text and disabled state.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Button = require(script.Parent.Button)
local GamepadButtonPrompt = require(script.Parent.GamepadButtonPrompt)
local ColorTheme = require(ReplicatedStorage.Source.SharedConstants.ColorTheme)
local TweenGroup = require(ReplicatedStorage.Source.TweenGroup)
local Keybind = require(ReplicatedStorage.Source.SharedConstants.Keybind)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local TWEEN_INFO = TweenInfo.new(0.1)
local DISABLED_BACKGROUND_COLOR = ColorTheme.LightGray
local DISABLED_TEXT_COLOR = ColorTheme.Gray
local ENABLED_TEXT_COLOR = ColorTheme.White

local prefabInstance: Frame =
	getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "SidebarActionButtonFramePrefab")
local keyCodeBindingInfo: Button.KeyCodeBindingInfo = {
	actionName = "ActivateSidebarActionButton",
	keyCodes = {
		Keybind.KeyboardPrimaryAction1,
		Keybind.KeyboardPrimaryAction2,
	},
	alwaysProcessedKeyCodes = {
		-- ButtonA is always processed by the game when a UI object is selected, but the
		-- selected object (list item) isn't where we're listening for activation. For this reason,
		-- we ignore gameProcessedEvent so we can manually fire the sidebar action button activation.
		Keybind.GamepadPrimaryAction,
	},
}

local function setupTweensForInstance(instance: Frame, properties: SidebarActionButtonProperties)
	local backgroundFrame: Frame = getInstance(instance, "BackgroundFrame")
	local textLabel: TextLabel = getInstance(instance, "Contents", "TextLabel")

	local tweenInGroup = TweenGroup.new(
		TweenService:Create(backgroundFrame, TWEEN_INFO, { BackgroundColor3 = properties.secondaryColor }),
		TweenService:Create(textLabel, TWEEN_INFO, { TextColor3 = ENABLED_TEXT_COLOR })
	)

	local tweenOutGroup = TweenGroup.new(
		TweenService:Create(backgroundFrame, TWEEN_INFO, { BackgroundColor3 = properties.primaryColor }),
		TweenService:Create(textLabel, TWEEN_INFO, { TextColor3 = ENABLED_TEXT_COLOR })
	)

	local tweenDisabledGroup = TweenGroup.new(
		TweenService:Create(backgroundFrame, TWEEN_INFO, {
			BackgroundColor3 = DISABLED_BACKGROUND_COLOR,
		}),
		TweenService:Create(textLabel, TWEEN_INFO, {
			TextColor3 = DISABLED_TEXT_COLOR,
		})
	)
	return tweenInGroup, tweenOutGroup, tweenDisabledGroup
end

export type SidebarActionButtonProperties = {
	primaryColor: Color3,
	secondaryColor: Color3,
}

local SidebarActionButton = {}
SidebarActionButton.__index = SidebarActionButton

export type ClassType = typeof(setmetatable(
	{} :: {
		_gamepadButtonPrompt: GamepadButtonPrompt.ClassType,
		_button: Button.ClassType,
		_instance: Frame,
		_tweenInGroup: TweenGroup.ClassType,
		_tweenOutGroup: TweenGroup.ClassType,
		_tweenDisabledGroup: TweenGroup.ClassType,
	},
	SidebarActionButton
))

function SidebarActionButton.new(properties: SidebarActionButtonProperties): ClassType
	local instance = prefabInstance:Clone() :: Frame

	local tweenInGroup, tweenOutGroup, tweenDisabledGroup = setupTweensForInstance(instance, properties)

	local self = {
		_gamepadButtonPrompt = GamepadButtonPrompt.new(Keybind.GamepadPrimaryAction),
		_button = Button.new(keyCodeBindingInfo),
		_instance = instance,
		_tweenInGroup = tweenInGroup,
		_tweenOutGroup = tweenOutGroup,
		_tweenDisabledGroup = tweenDisabledGroup,
	}

	setmetatable(self, SidebarActionButton)

	self:_setup()

	return self
end

function SidebarActionButton.setParent(self: ClassType, parent: GuiObject)
	self._instance.Parent = parent
end

function SidebarActionButton._setup(self: ClassType)
	local contents: Frame = getInstance(self._instance, "Contents")
	local buttonHolder: Frame = getInstance(self._instance, "ButtonHolder")

	self._gamepadButtonPrompt:setParent(contents)
	self._button:setParent(buttonHolder)

	self:_setupConnections()
	self._button:setSelectable(false)

	-- Begin by tweening to the default state
	self._tweenOutGroup:play()
end

function SidebarActionButton.getButton(self: ClassType)
	return self._button
end

function SidebarActionButton.getInstance(self: ClassType)
	return self._instance
end

function SidebarActionButton._setupConnections(self: ClassType)
	self._button.hovered:Connect(function(isHovering: any)
		if not self._button:isEnabled() then
			return
		end

		if isHovering :: boolean then
			self._tweenInGroup:play()
		else
			self._tweenOutGroup:play()
		end
	end)
end

function SidebarActionButton.setEnabled(self: ClassType, isEnabled: boolean)
	local disabledFrame: Frame = getInstance(self._instance, "DisabledFrame")

	disabledFrame.Visible = not isEnabled
	self._button:setEnabled(isEnabled)
	self._gamepadButtonPrompt:setEnabled(isEnabled)

	if isEnabled then
		self._tweenOutGroup:play()
	else
		self._tweenDisabledGroup:play()
	end
end

function SidebarActionButton.setText(self: ClassType, text: string, iconId: number?)
	local textLabel: TextLabel = getInstance(self._instance, "Contents", "TextLabel")
	textLabel.Text = text

	local imageLabel: ImageLabel = getInstance(self._instance, "Contents", "ImageLabel")
	imageLabel.Image = if iconId
		then PlayerFacingString.ImageAsset.Prefix .. tostring(iconId)
		else PlayerFacingString.ImageAsset.None
	imageLabel.Visible = if iconId then true else false
end

function SidebarActionButton.reset(self: ClassType)
	self:setEnabled(false)
	local prefabTextLabel: TextLabel = getInstance(prefabInstance, "Contents", "TextLabel")
	self:setText(prefabTextLabel.Text)
end

function SidebarActionButton.destroy(self: ClassType)
	self._button:destroy()
	self._gamepadButtonPrompt:destroy()
	self._instance:Destroy()
end

return SidebarActionButton
