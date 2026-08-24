--!strict

--[[
	A button to open the inventory view

	This is a singleton that can not be 'stopped' so we do not need to store connections to disconnect later.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local Button = require(ReplicatedStorage.Source.UI.UIComponents.Button)
local InventoryAnimator = require(script.Parent.Parent.InventoryAnimator)
local GamepadButtonPrompt = require(ReplicatedStorage.Source.UI.UIComponents.GamepadButtonPrompt)
local Keybind = require(ReplicatedStorage.Source.SharedConstants.Keybind)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local LAYER_ID: UILayerId.EnumType = UILayerId.InventoryButton
local HOVER_SIZE_SCALAR = 1.2
local HOVER_TWEEN_INFO = TweenInfo.new(0.2)
local HOVER_ROTATION_DEGREES = -5
local KEYCODE_BINDING_INFO: Button.KeyCodeBindingInfo = {
	actionName = "OpenInventory",
	keyCodes = {
		Keybind.GamepadInventoryOpenButton,
		Keybind.KeyboardInventoryOpenButton,
	},
}

local inventoryButtonPrefab: ScreenGui =
	getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "InventoryButtonPrefab")
local prefabIconImageLabel: ImageLabel = getInstance(inventoryButtonPrefab, "IconFrame", "Icon")
local originalSize = prefabIconImageLabel.Size
local hoveredSize = UDim2.fromScale(originalSize.X.Scale * HOVER_SIZE_SCALAR, originalSize.Y.Scale * HOVER_SIZE_SCALAR)

local instance = inventoryButtonPrefab:Clone()
local iconImageLabel: ImageLabel = getInstance(instance, "IconFrame", "Icon")

local UIInventoryButton = {}
UIInventoryButton._instance = instance
UIInventoryButton._inventoryAnimator = InventoryAnimator.new(UIInventoryButton._instance)
UIInventoryButton._button = Button.new(KEYCODE_BINDING_INFO)
UIInventoryButton._hoveredTween =
	TweenService:Create(iconImageLabel, HOVER_TWEEN_INFO, { Size = hoveredSize, Rotation = HOVER_ROTATION_DEGREES })
UIInventoryButton._unhoveredTween =
	TweenService:Create(iconImageLabel, HOVER_TWEEN_INFO, { Size = originalSize, Rotation = 0 })

function UIInventoryButton.setup(parent: Instance)
	UIInventoryButton._instance.Parent = parent
	UIInventoryButton._button:setParent(iconImageLabel)

	UIInventoryButton._setupButton()
	UIInventoryButton._registerLayer()
end

function UIInventoryButton.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

function UIInventoryButton.getInstance()
	return UIInventoryButton._instance
end

function UIInventoryButton._registerLayer()
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.HeadsUpDisplay, UIInventoryButton)

	visibilityChanged:Connect(function(isVisible: any)
		UIInventoryButton._button:setEnabled(isVisible :: boolean)
		UIInventoryButton._instance.Enabled = isVisible :: boolean
	end)

	UIHandler.show(LAYER_ID)
end

function UIInventoryButton._setupButton()
	UIInventoryButton._button:setSelectable(false)

	local gamepadButtonPrompt = GamepadButtonPrompt.new(Keybind.GamepadInventoryOpenButton)
	gamepadButtonPrompt:setParent(iconImageLabel)

	UIInventoryButton._button.hovered:Connect(function(isHovering: any)
		if isHovering :: boolean then
			UIInventoryButton._hoveredTween:Play()
		else
			UIInventoryButton._unhoveredTween:Play()
		end
	end)

	UIInventoryButton._button.activated:Connect(function()
		UIHandler.show(UILayerId.Inventory)
	end)
end

return UIInventoryButton
