--!strict

--[[
	A UI component that shows a warning message when the player's data fails to load or save
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local PlayerDataErrorType = require(ReplicatedStorage.Source.PlayerData.PlayerDataErrorType)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local LAYER_ID: UILayerId.EnumType = UILayerId.DataErrorNotice
-- TODO: Move to a central constants file
local MESSAGES: { [string]: { [PlayerDataErrorType.EnumType]: { [string]: string } } } = {
	Loading = {
		[PlayerDataErrorType.DataStoreError] = {
			Heading = '⚠️ <font color="rgb(253,124,112)">Warning:</font> Data Load Error ⚠️',
			Description = 'An error occurred while loading your data. Nothing you do during this session will save. <font color="rgb(253,124,112)">Your saved data is safe</font>. Please rejoin the game.',
		},
		[PlayerDataErrorType.SessionLocked] = {
			Heading = '⚠️ <font color="rgb(253,124,112)">Warning:</font> Data Load Error ⚠️',
			Description = 'Your data could not be loaded as you currently have another active session. This usually happens when you have recently left the game. <font color="rgb(253,124,112)">Your saved data is safe</font>. Please rejoin the game.',
		},
	},
	Saving = {
		[PlayerDataErrorType.DataStoreError] = {
			Heading = '⚠️ <font color="rgb(253,124,112)">Warning:</font> Data Save Error ⚠️',
			Description = 'An error occurred while attempting to save your data. <font color="rgb(253,124,112)">If you leave the game now, recent progress may be lost.</font> This notice will be removed when your data is successfully saved.',
		},
		-- It's not possible to have two active sessions in normal use so the message below should only be seen by developers:
		[PlayerDataErrorType.SessionLocked] = {
			Heading = '⚠️ <font color="rgb(253,124,112)">Warning:</font> Data Save Error ⚠️',
			Description = "Your data could not be saved as this session is out of date. Please rejoin the game.",
		},
	},
}

local tweenInfo = TweenInfo.new(0.5)
local dataErrorNoticePrefab: ScreenGui =
	getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "DataErrorNoticePrefab")
local instance = dataErrorNoticePrefab:Clone()
local canvasGroup: CanvasGroup = getInstance(instance, "CanvasGroup")
local originalPosition = canvasGroup.Position
local disabledPosition = UDim2.new(
	originalPosition.X.Scale,
	originalPosition.X.Offset,
	originalPosition.Y.Scale / 2,
	originalPosition.Y.Offset / 2
)

local UIDataErrorNotice = {}
UIDataErrorNotice._instance = instance
UIDataErrorNotice._enableTween =
	TweenService:Create(canvasGroup, tweenInfo, { GroupTransparency = 0, Position = originalPosition })
UIDataErrorNotice._disableTween = TweenService:Create(canvasGroup, tweenInfo, {
	GroupTransparency = 1,
	Position = disabledPosition,
})

function UIDataErrorNotice._enable(isLoading: boolean, errorType: PlayerDataErrorType.EnumType)
	local messages = MESSAGES[isLoading and "Loading" or "Saving"][errorType]

	local headingText: TextLabel = getInstance(UIDataErrorNotice._instance, "CanvasGroup", "HeadingText")
	headingText.Text = messages.Heading

	local detailText: TextLabel = getInstance(UIDataErrorNotice._instance, "CanvasGroup", "DetailText")
	detailText.Text = messages.Description

	UIHandler.show(LAYER_ID)
end

function UIDataErrorNotice._disable()
	UIHandler.hide(LAYER_ID)
end

function UIDataErrorNotice.setup(parent: Instance)
	canvasGroup.GroupTransparency = 1
	UIDataErrorNotice._instance.Parent = parent

	UIDataErrorNotice._registerLayer()
	UIDataErrorNotice._disable()
	UIDataErrorNotice._listenForErrors()
end

function UIDataErrorNotice._registerLayer()
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.HeadsUpDisplay, UIDataErrorNotice)

	visibilityChanged:Connect(function(isVisible: any)
		local tween = if isVisible then UIDataErrorNotice._enableTween else UIDataErrorNotice._disableTween
		tween:Play()
	end)
end

function UIDataErrorNotice._listenForErrors()
	if PlayerDataClient.hasLoadingErrored() then
		local errorType: PlayerDataErrorType.EnumType = PlayerDataClient.getLoadError() :: PlayerDataErrorType.EnumType
		assert(errorType, "Missing error type after loading errored")
		UIDataErrorNotice._enable(true, errorType)
	else
		PlayerDataClient.saved:Connect(function(success: any, errorType: any?)
			if success :: boolean then
				UIDataErrorNotice._disable()
			else
				UIDataErrorNotice._enable(false, errorType :: PlayerDataErrorType.EnumType)
			end
		end)
	end
end

function UIDataErrorNotice.getLayerId(): UILayerId.EnumType
	return LAYER_ID :: UILayerId.EnumType
end

function UIDataErrorNotice.getInstance()
	return UIDataErrorNotice._instance
end

return UIDataErrorNotice
