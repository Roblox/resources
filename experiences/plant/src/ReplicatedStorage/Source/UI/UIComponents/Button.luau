--!strict

--[[
	An object with hover / pressed / selected and activated listeners

	- Hover: A state of 'hovering' when a physical or virtual mouse cursor is over the button
	- Press: A state of 'depression' when the button is being actively engaged by a mouse click, gamepad press, or finger touch
	- Selected: A state of 'engagement' where the button is currently being selected in gamepad navigation
	- Activated: A discrete activation of the button, via mouse click, gamepad press or finger touch (distinct from press, which is a state that begins and ends)

	Takes optional keycodes to bind to the activated event for ease of use creating keyboard shortcuts and gamepad input compatibility
--]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local InputCategorizer = require(ReplicatedStorage.Source.InputCategorizer)
local InputCategory = require(ReplicatedStorage.Source.SharedConstants.InputCategory)
local Signal = require(ReplicatedStorage.Source.Signal)
local Connections = require(ReplicatedStorage.Source.Connections)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local prefabInstance: GuiButton = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "ButtonPrefab")
local buttonSoundEffect: Sound = getInstance(SoundService, "SoundEffects", "Button")

export type KeyCodeBindingInfo = {
	actionName: string,
	keyCodes: { Enum.KeyCode }?, -- KeyCodes in this list are not processed if the gameProcessedEvent is true
	alwaysProcessedKeyCodes: { Enum.KeyCode }?, -- KeyCodes in this list are always processed, even if the gameProcessedEvent is true
}

local Button = {}
Button.__index = Button

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: GuiButton,
		_connections: Connections.ClassType,
		_hovering: boolean,
		_pressing: boolean,
		_selecting: boolean,
		_isEnabled: boolean,
		_keyCodeBindingInfo: KeyCodeBindingInfo?,
		hovered: Signal.ClassType,
		selected: Signal.ClassType,
		pressed: Signal.ClassType,
		activated: Signal.ClassType,
	},
	Button
))

function Button.new(keyCodeBindingInfo: KeyCodeBindingInfo?): ClassType
	local self = {
		_instance = prefabInstance:Clone(),
		_connections = Connections.new(),
		_hovering = false,
		_pressing = false,
		_selecting = false,
		_isEnabled = false,
		_keyCodeBindingInfo = keyCodeBindingInfo,
		hovered = Signal.new(),
		selected = Signal.new(),
		pressed = Signal.new(),
		activated = Signal.new(),
	}
	setmetatable(self, Button)

	self:setEnabled(true)

	return self
end

function Button.setParent(self: ClassType, parent: Instance)
	self._instance.Parent = parent
end

function Button.isHovering(self: ClassType)
	return self._hovering
end

function Button.isPressed(self: ClassType)
	return self._pressing
end

function Button.isSelected(self: ClassType)
	return self._selecting
end

function Button.getInstance(self: ClassType)
	return self._instance
end

function Button.setEnabled(self: ClassType, isEnabled: boolean)
	if isEnabled then
		self:_enableInput()
	else
		self:_disableInput()
	end
	self._isEnabled = isEnabled
end

function Button.setSelectable(self: ClassType, isSelectable: boolean)
	self._instance.Selectable = isSelectable
end

function Button.isEnabled(self: ClassType)
	return self._isEnabled
end

function Button._onHover(self: ClassType, isHovering: boolean)
	self._hovering = isHovering

	self.hovered:Fire(isHovering, self._instance)
end

function Button._onPress(self: ClassType, isPressing: boolean, screenPosition: Vector2)
	self._pressing = isPressing

	self.pressed:Fire(isPressing, self._instance, screenPosition)
end

function Button._onSelected(self: ClassType, isSelected: boolean)
	self._selecting = isSelected

	self.selected:Fire(isSelected, self._instance)
end

function Button._onActivated(self: ClassType)
	if not self:isEnabled() then
		return
	end

	buttonSoundEffect:Play()

	self.activated:Fire(self._instance)
end
function Button._enableInput(self: ClassType)
	-- Prevent duplicate connections if setEnabled is ever called with true multiple times
	if self._isEnabled then
		return
	end

	self:_listenForHover()
	self:_listenForSelected()
	self:_listenForPress()
	self:_listenForActivation()
	self:_connectInputBindings()
end

function Button._disableInput(self: ClassType)
	self._connections:disconnect()
end

function Button._listenForHover(self: ClassType)
	local mouseEnterConnection = self._instance.MouseEnter:Connect(function()
		self:_onHover(true)
	end)

	local mouseLeaveConnection = self._instance.MouseLeave:Connect(function()
		self:_onHover(false)
	end)

	self._connections:add(mouseEnterConnection, mouseLeaveConnection)
end

function Button._listenForSelected(self: ClassType)
	local selectionGainedConnection = self._instance.SelectionGained:Connect(function()
		self:_onSelected(true)
	end)
	local selectionLostConnection = self._instance.SelectionLost:Connect(function()
		self:_onSelected(false)
	end)

	self._connections:add(selectionGainedConnection, selectionLostConnection)
end

function Button._listenForPress(self: ClassType)
	-- Despite its naming, GuiButton.MouseButton1Down will fire for mouse, touch and gamepad interactions
	local buttonDownConnection = self._instance.MouseButton1Down:Connect(function(x: number, y: number)
		self:_onPress(true, Vector2.new(x, y))
	end)

	local buttonUpConnection = self._instance.MouseButton1Up:Connect(function(x: number, y: number)
		self:_onPress(false, Vector2.new(x, y))
	end)

	self._connections:add(buttonDownConnection, buttonUpConnection)
end

function Button._listenForActivation(self: ClassType)
	local activatedConnection = self._instance.Activated:Connect(function()
		self:_onActivated()
	end)

	self._connections:add(activatedConnection)
end

function Button._connectInputBindings(self: ClassType)
	if not self._keyCodeBindingInfo then
		return
	end
	local keyCodeBindingInfo = self._keyCodeBindingInfo :: KeyCodeBindingInfo

	-- Can't use ContextActionService if we want to listen to activation buttons like ButtonA, because
	-- during Select mode, ButtonA presses are considered gameProcessedEvents. ContextActionService ignores
	-- any gameProcessedEvents, whereas with UserInputService, we can still listen to these events.
	local inputConnection = UserInputService.InputBegan:Connect(
		function(input: InputObject, gameProcessedEvent: boolean)
			local inputCategory = InputCategorizer.getCategoryOf(input.UserInputType)

			if inputCategory ~= InputCategory.Gamepad and inputCategory ~= InputCategory.KeyboardMouse then
				return
			end

			local alwaysProcess = table.find(keyCodeBindingInfo.alwaysProcessedKeyCodes or {}, input.KeyCode)
			if gameProcessedEvent and not alwaysProcess then
				return
			end

			if alwaysProcess or table.find(keyCodeBindingInfo.keyCodes or {}, input.KeyCode) then
				self:_onActivated()
			end
		end
	)

	self._connections:add(inputConnection)
end

function Button.destroy(self: ClassType)
	self.hovered:DisconnectAll()
	self.pressed:DisconnectAll()
	self.activated:DisconnectAll()
	self.selected:DisconnectAll()

	self:_disableInput()
end

return Button
