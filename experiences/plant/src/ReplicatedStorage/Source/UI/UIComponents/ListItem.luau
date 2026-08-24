--!strict

--[[
	UIComponent for a list item in the Categories view (shop and seed selection)
--]]

-- TODO: Add support for "Selected" toggle state such that it stays "selected" after being
-- activated, even after mousing off. (re: toggled state)
-- This allows a user to easily find which list item is currently showing on the sidebar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TweenGroup = require(ReplicatedStorage.Source.TweenGroup)
local ModelViewport = require(script.Parent.ModelViewport)
local Signal = require(ReplicatedStorage.Source.Signal)
local Button = require(script.Parent.Button)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getMetadataFromItemId = require(ReplicatedStorage.Source.Utility.Farm.getMetadataFromItemId)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local prefabInstance: Frame = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "ListItemPrefab")

local TWEEN_INFO = TweenInfo.new(0.1)
local HOVER_POSITION_OFFSET = UDim2.new(0, 5, 0, 0)

local ListItem = {}
ListItem.__index = ListItem

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Frame,
		_isEnabled: boolean,
		_button: Button.ClassType,
		_modelViewport: ModelViewport.ClassType?,
		_tweenInGroup: TweenGroup.ClassType?,
		_tweenOutGroup: TweenGroup.ClassType?,
		enabledChanged: Signal.ClassType,
	},
	ListItem
))

function ListItem.new(itemId: string, listOrder: number): ClassType
	local instance = prefabInstance:Clone() :: Frame

	local self = {
		_instance = instance,
		_isEnabled = true,
		_button = Button.new(),
		_modelViewport = nil,
		_tweenInGroup = nil,
		_tweenOutGroup = nil,
		enabledChanged = Signal.new(),
	}
	setmetatable(self, ListItem)

	self:_setup(itemId, listOrder)

	return self
end

function ListItem.setParent(self: ClassType, parent: Instance)
	self._instance.Parent = parent
end

function ListItem._setup(self: ClassType, itemId: string, listOrder: number)
	local metadata = getMetadataFromItemId(itemId)
	self:_setupTweens(metadata.primaryColor, metadata.secondaryColor)
	self:_setupPreviewModel(metadata.itemModel)
	self:_setNameAndDescription(metadata.name, metadata.iconId, metadata.descriptionShort)
	self:_setupColor(metadata.primaryColor, metadata.secondaryColor)

	self:_listenForInput()

	self._button:setParent(self._instance)

	self._instance.LayoutOrder = listOrder
	self._instance.SelectionOrder = listOrder
end

function ListItem._setupTweens(self: ClassType, primaryColor: Color3, secondaryColor: Color3)
	local containerFrame: Frame = getInstance(self._instance, "ContainerFrame")
	local itemNameTextLabel: TextLabel =
		getInstance(containerFrame, "ContentsFrame", "DescriptionFrame", "ItemNameFrame", "ItemNameTextLabel")
	local itemAmountTextLabel: Frame =
		getInstance(containerFrame, "ContentsFrame", "AmountFrame", "ItemAmountTextLabel")

	self._tweenInGroup = TweenGroup.new(
		TweenService:Create(containerFrame, TWEEN_INFO, { Position = HOVER_POSITION_OFFSET }),
		TweenService:Create(itemNameTextLabel, TWEEN_INFO, { TextColor3 = secondaryColor }),
		TweenService:Create(itemAmountTextLabel, TWEEN_INFO, { TextColor3 = secondaryColor })
	)

	self._tweenOutGroup = TweenGroup.new(
		TweenService:Create(containerFrame, TWEEN_INFO, { Position = UDim2.new(0, 0, 0, 0) }),
		TweenService:Create(itemNameTextLabel, TWEEN_INFO, { TextColor3 = primaryColor }),
		TweenService:Create(itemAmountTextLabel, TWEEN_INFO, { TextColor3 = primaryColor })
	)
end

function ListItem._listenForInput(self: ClassType)
	-- These connections will be disconnected when the Button is destroyed
	-- so we do not need to store them
	self._button.hovered:Connect(function(isHovering: any)
		self:_onHover(isHovering :: boolean)
	end)

	self._button.selected:Connect(function(isSelected: any)
		self:_onSelected(isSelected :: boolean)
	end)

	self._button.pressed:Connect(function(isPressed: any, _: any, screenPosition: any)
		self:_onPressed(isPressed :: boolean, screenPosition :: Vector2)
	end)
end

function ListItem._onHover(self: ClassType, isHovering: boolean)
	if isHovering then
		if self._isEnabled then
			local tweenInGroup = self._tweenInGroup :: TweenGroup.ClassType
			tweenInGroup:play()
		end
	else
		local tweenOutGroup = self._tweenOutGroup :: TweenGroup.ClassType
		tweenOutGroup:play()
	end
end

function ListItem._onPressed(self: ClassType, isPressed: boolean, screenPosition: Vector2)
	-- TODO: Play sound
	-- TODO: Animated pressed effect (using screenPosition?)
end

function ListItem._onSelected(self: ClassType, isSelected: boolean)
	-- Show hover effects when the item is selected with a gamepad
	self:_onHover(isSelected)
end

function ListItem._setupPreviewModel(self: ClassType, previewModel: Model)
	local modelViewportHolder: Frame =
		getInstance(self._instance, "ContainerFrame", "ContentsFrame", "ItemIconFrame", "ModelViewportHolder")

	local modelViewport = ModelViewport.new({
		model = previewModel,
	})
	modelViewport:setParent(modelViewportHolder)
	self._modelViewport = modelViewport
end

function ListItem._setNameAndDescription(self: ClassType, name: string, iconId: number?, description: string)
	local descriptionFrame: Frame = getInstance(self._instance, "ContainerFrame", "ContentsFrame", "DescriptionFrame")
	local nameFrame: Frame = getInstance(descriptionFrame, "ItemNameFrame")
	local nameTextLabel: TextLabel = getInstance(nameFrame, "ItemNameTextLabel")
	local descriptionTextLabel: TextLabel = getInstance(descriptionFrame, "ItemDescriptionTextLabel")
	local nameIconLabel: ImageLabel = getInstance(nameFrame, "ItemNameIcon")

	nameTextLabel.Text = name
	nameIconLabel.Image = if iconId
		then PlayerFacingString.ImageAsset.Prefix .. iconId
		else PlayerFacingString.ImageAsset.None
	descriptionTextLabel.Text = description
end

function ListItem._setupColor(self: ClassType, primaryColor: Color3, secondaryColor: Color3)
	local nameTextLabel: TextLabel = getInstance(
		self._instance,
		"ContainerFrame",
		"ContentsFrame",
		"DescriptionFrame",
		"ItemNameFrame",
		"ItemNameTextLabel"
	)
	local amountTextLabel: TextLabel =
		getInstance(self._instance, "ContainerFrame", "ContentsFrame", "AmountFrame", "ItemAmountTextLabel")
	local iconBackgroundFrame: Frame = getInstance(self._instance, "ContainerFrame", "ContentsFrame", "ItemIconFrame")

	nameTextLabel.TextColor3 = primaryColor
	amountTextLabel.TextColor3 = primaryColor
	iconBackgroundFrame.BackgroundColor3 = secondaryColor
end

function ListItem.getInstance(self: ClassType)
	return self._instance
end

function ListItem.getButton(self: ClassType)
	return self._button
end

function ListItem.setAmountText(self: ClassType, text: string)
	local itemAmountTextLabel: TextLabel =
		getInstance(self._instance, "ContainerFrame", "ContentsFrame", "AmountFrame", "ItemAmountTextLabel")

	itemAmountTextLabel.Text = tostring(text)
end

function ListItem.setEnabled(self: ClassType, isEnabled: boolean)
	local enabledChanged = self._isEnabled ~= isEnabled
	self._isEnabled = isEnabled

	local disabledFrame: Frame = getInstance(self._instance, "ContainerFrame", "DisabledFrame")
	disabledFrame.Visible = not isEnabled

	self._button:setEnabled(isEnabled)

	if enabledChanged then
		self.enabledChanged:Fire(isEnabled)
	end
end

function ListItem.setVisible(self: ClassType, isVisible: boolean)
	self._instance.Visible = isVisible
end

function ListItem.destroy(self: ClassType)
	local modelViewport = self._modelViewport :: ModelViewport.ClassType
	modelViewport:destroy()
	self._button:destroy()
	self.enabledChanged:DisconnectAll()

	if self._instance.Parent then
		self._instance:Destroy()
	end
end

return ListItem
