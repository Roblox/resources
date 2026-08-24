--!strict

--[[
	Creates UI layers and connects them to zones.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local GamepadMouseDisabler = require(script.Parent.GamepadMouseDisabler)
local UIZoneHandler = require(script.Parent.UIZoneHandler)
local UISeedMarket = require(script.Parent.UILayers.UISeedMarket)
local UIPlantSeed = require(script.Parent.UILayers.UIPlantSeed)
local UIPlacePot = require(script.Parent.UILayers.UIPlacePot)
local UIGardenStore = require(script.Parent.UILayers.UIGardenStore)
local UIBuyCoins = require(script.Parent.UILayers.UIBuyCoins)
local UIDataErrorNotice = require(script.Parent.UILayers.UIDataErrorNotice)
local UICoinIndicator = require(script.Parent.UILayers.UICoinIndicator)
local UIInventory = require(script.Parent.UILayers.UIInventory)
local UIInventoryButton = require(script.Parent.UILayers.UIInventoryButton)
local UIResetDataButton = require(script.Parent.UILayers.UIResetDataButton)
local UILayerIdByZoneId = require(ReplicatedStorage.Source.SharedConstants.UILayerIdByZoneId)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local ZoneIdTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZoneIdTag)
local ViewingMenuEffect = require(ReplicatedStorage.Source.ViewingMenuEffect)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local localPlayer = Players.LocalPlayer :: Player
local playerGui: PlayerGui = getInstance(localPlayer, "PlayerGui")
local ZoneIdByUILayerId = Freeze.Dictionary.flip(UILayerIdByZoneId) :: { [UILayerId.EnumType]: ZoneIdTag.EnumType }

local UISetup = {}

type UILayer = {
	setup: (Instance) -> (),
	getLayerId: () -> UILayerId.EnumType,
}

local uiLayerSingletons: { UILayer } = {
	UISeedMarket,
	UIGardenStore,
	UIPlantSeed, -- TODO: Show size of pot you're attempting to plant in on UI?
	UIPlacePot, -- TODO: Show spot number of pot you're placing on UI?
	UIBuyCoins,
	UIDataErrorNotice,
	UICoinIndicator,
	UIInventory,
	UIInventoryButton,
}

function UISetup.start()
	-- Prevents the mouse cursor from getting in the way while navigating with a gamepad
	GamepadMouseDisabler.start()

	-- Disables the "Selection mode" toggle button functionality of gamepads because we manually
	-- set the SelectedObject for more customized behavior
	GuiService.AutoSelectGuiEnabled = false

	-- UI layer singletons setup
	for _, uiLayerSingleton in ipairs(uiLayerSingletons) do
		UISetup._setupLayerSingleton(uiLayerSingleton)
	end

	-- Studio-only feature allowing a developer to easily reset their data for testing purposes
	if RunService:IsStudio() then
		UISetup._setupLayerSingleton(UIResetDataButton)
	end

	-- To remove Roblox's default blue selection image frame, we need to replace it with a transparent
	-- replacement
	local transparentFrame = Instance.new("Frame")
	transparentFrame.BackgroundTransparency = 1
	playerGui.SelectionImageObject = transparentFrame

	ViewingMenuEffect.start()
end

function UISetup._setupLayerSingleton(uiLayerSingleton: UILayer)
	uiLayerSingleton.setup(playerGui)

	local uiLayerId: UILayerId.EnumType = uiLayerSingleton.getLayerId()
	local zoneId: ZoneIdTag.EnumType = ZoneIdByUILayerId[uiLayerId]
	if zoneId then
		UIZoneHandler.connectUiToZone(uiLayerId, zoneId)
	end
end

return UISetup
