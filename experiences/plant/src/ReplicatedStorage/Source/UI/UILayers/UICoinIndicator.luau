--!strict

--[[
	A UI component that shows the current number of coins the player has.
	Uses CoinAnimator to animate changes in coin amounts to make these
	changes more apparent to the player.

	This layer is always visible, so we do not need to register it with UIHandler.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CoinAnimator = require(script.Parent.Parent.CoinAnimator)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local Button = require(ReplicatedStorage.Source.UI.UIComponents.Button)
local GamepadButtonPrompt = require(ReplicatedStorage.Source.UI.UIComponents.GamepadButtonPrompt)
local Keybind = require(ReplicatedStorage.Source.SharedConstants.Keybind)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local LAYER_ID: UILayerId.EnumType = UILayerId.CoinIndicator
local HOVER_SIZE_SCALAR = 1.2
local HOVER_TWEEN_INFO = TweenInfo.new(0.2)
local KEYCODE_BINDING_INFO: Button.KeyCodeBindingInfo = {
	actionName = "OpenCurrencyShop",
	keyCodes = {
		Keybind.GamepadPurchaseCurrencyShortcut,
		Keybind.KeyboardPurchaseCurrencyShortcut,
	},
}

local coinIndicatorPrefab: ScreenGui = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "CoinIndicatorPrefab")
local prefabCoinPlusIconFrame: ImageLabel =
	getInstance(coinIndicatorPrefab, "Background", "CoinIconButtonHolder", "PlusIconFrame")
local originalSize = prefabCoinPlusIconFrame.Size
local hoveredSize = UDim2.fromScale(originalSize.X.Scale * HOVER_SIZE_SCALAR, originalSize.Y.Scale * HOVER_SIZE_SCALAR)

local instance = coinIndicatorPrefab:Clone()
local coinIconButtonHolder: Frame = getInstance(instance, "Background", "CoinIconButtonHolder")
local coinPlusIconFrame: ImageLabel = getInstance(coinIconButtonHolder, "PlusIconFrame")

local UICoinIndicator = {}
UICoinIndicator._instance = instance
UICoinIndicator._button = Button.new(KEYCODE_BINDING_INFO)
UICoinIndicator._hoveredTween = TweenService:Create(coinPlusIconFrame, HOVER_TWEEN_INFO, { Size = hoveredSize })
UICoinIndicator._unhoveredTween = TweenService:Create(coinPlusIconFrame, HOVER_TWEEN_INFO, { Size = originalSize })

function UICoinIndicator.setup(parent: Instance)
	UICoinIndicator._instance.Parent = parent
	UICoinIndicator._coinAnimator = CoinAnimator.new(UICoinIndicator._instance)
	UICoinIndicator._setupBuyCurrencyButton()
end

function UICoinIndicator._setupBuyCurrencyButton()
	UICoinIndicator._button:setSelectable(false)
	UICoinIndicator._button:setParent(coinIconButtonHolder)

	local gamepadButtonPrompt = GamepadButtonPrompt.new(Keybind.GamepadPurchaseCurrencyShortcut)
	gamepadButtonPrompt:setParent(coinIconButtonHolder)

	UICoinIndicator._button.hovered:Connect(function(isHovering: any)
		if isHovering :: boolean then
			UICoinIndicator._hoveredTween:Play()
		else
			UICoinIndicator._unhoveredTween:Play()
		end
	end)

	UICoinIndicator._button.activated:Connect(function()
		UIHandler.show(UILayerId.BuyCoins)
	end)
end

function UICoinIndicator.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

return UICoinIndicator
