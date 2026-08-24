--!strict

--[[
	Displays an ImageLabel highlight over a given GuiObject and plays an in-out size animation.
	The prefab is set up with a higher DisplayOrder property than the other ScreenGuis, so that this
	highlight appears on top of other guis.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local Connections = require(ReplicatedStorage.Source.Connections)
local connectAll = require(ReplicatedStorage.Source.Utility.connectAll)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local localPlayer = Players.LocalPlayer :: Player
local playerGui: PlayerGui = getInstance(localPlayer, "PlayerGui")
local highlightPrefab: ScreenGui = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "UIHighlightPrefab")

local DEFAULT_ANIMATED_SIZE_GOAL = UDim2.fromOffset(50, 50)

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, true, 0)

local UIHighlight = {}
UIHighlight.__index = UIHighlight

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: ScreenGui,
		_connections: Connections.ClassType,
	},
	UIHighlight
))

function UIHighlight.new(highlightedGuiObject: GuiObject, animatedSizeAddition: UDim2?): ClassType
	local self = {
		_instance = highlightPrefab:Clone(),
		_connections = Connections.new(),
	}

	self._instance.Name = highlightedGuiObject.Name .. "UIHighlight"
	setmetatable(self, UIHighlight)

	self:_setup(highlightedGuiObject, animatedSizeAddition)

	return self
end

function UIHighlight._setup(self: ClassType, highlightedGuiObject: GuiObject, animatedSizeAddition: UDim2?)
	local sizeDifference = animatedSizeAddition or DEFAULT_ANIMATED_SIZE_GOAL
	local baseFrame: Frame = getInstance(self._instance, "BaseFrame")

	local function updateBaseToMatchHighlighted()
		baseFrame.Size = UDim2.fromOffset(highlightedGuiObject.AbsoluteSize.X, highlightedGuiObject.AbsoluteSize.Y)
		baseFrame.Position =
			UDim2.fromOffset(highlightedGuiObject.AbsolutePosition.X, highlightedGuiObject.AbsolutePosition.Y)
		baseFrame.Visible = self:_isVisibleRecursive(highlightedGuiObject)
	end

	-- Ensure the BaseFrame matches the highlighted object's size and position so the highlight stays over the object
	local newConnections = connectAll(
		Freeze.List.concat({
			highlightedGuiObject:GetPropertyChangedSignal("AbsolutePosition"),
			highlightedGuiObject:GetPropertyChangedSignal("AbsoluteSize"),
		}, self:_getVisibilitySignalsRecursive(highlightedGuiObject)),
		updateBaseToMatchHighlighted
	)
	self._connections:add(table.unpack(newConnections))

	updateBaseToMatchHighlighted()

	self._instance.Parent = playerGui
	local imageLabel: ImageLabel = getInstance(baseFrame, "ImageLabel")
	TweenService:Create(imageLabel, tweenInfo, { Size = imageLabel.Size + sizeDifference }):Play()
end

-- Visibility of an element requires that all its parents are visible and enabled, so this
-- gets signals for all those relevant property changed events.
function UIHighlight._getVisibilitySignalsRecursive(
	self: ClassType,
	guiObject: Instance,
	signalsMaybe: { RBXScriptSignal }?
)
	local signals: { RBXScriptSignal } = signalsMaybe or {
		guiObject.AncestryChanged,
	}

	if guiObject:IsA("GuiObject") then
		table.insert(signals, guiObject:GetPropertyChangedSignal("Visible"))
	end

	if guiObject:IsA("ScreenGui") then
		table.insert(signals, guiObject:GetPropertyChangedSignal("Enabled"))
	end

	if not guiObject:IsDescendantOf(playerGui) then
		return signals
	end

	return self:_getVisibilitySignalsRecursive(guiObject.Parent :: Instance, signals)
end

function UIHighlight._isVisibleRecursive(self: ClassType, guiObject: Instance)
	local maybeParent = guiObject.Parent
	if not (maybeParent and maybeParent:IsDescendantOf(playerGui)) then
		return false
	end

	if guiObject:IsA("GuiObject") and not guiObject.Visible then
		return false
	end

	local parent = maybeParent :: Instance

	if parent:IsA("ScreenGui") then
		return parent.Enabled
	end

	return self:_isVisibleRecursive(parent)
end

function UIHighlight.destroy(self: ClassType)
	self._connections:disconnect()

	self._instance:Destroy()
end

return UIHighlight
