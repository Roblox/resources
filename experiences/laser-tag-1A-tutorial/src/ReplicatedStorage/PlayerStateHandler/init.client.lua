--[[
	Contains functions that can be called to trigger behavior based on changes to the 'playerState' attribute.
	There are three defined events:
		- Player is selecting a blaster
		- Player is playing
		- Player is tagged out

	These event responses are logically grouped together in this file because they require
	similar behavior of enabling or disabling player controls, camera movement, and which UI
	layer is visible.

	Destroying the force field is also scheduled whenever the player begins selecting a blaster.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerState = require(ReplicatedStorage.PlayerState)
local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local BlasterState = require(ReplicatedStorage.Blaster.BlasterState)
local togglePlayerMovement = require(script.togglePlayerMovement)
local togglePlayerCamera = require(script.togglePlayerCamera)
local scheduleDestroyForceField = require(ReplicatedStorage.scheduleDestroyForceField)

local localPlayer = Players.LocalPlayer

local playerGui = localPlayer.PlayerGui
local guiLayers = {
	playerGui:WaitForChild("HUDGui"),
	playerGui:WaitForChild("OutStateGui"),
	playerGui:WaitForChild("PickABlasterGui"),
}

-- Disable all UI Layers except the given exception
local function setGuiExclusivelyEnabled(enabledGui)
	-- guiLayers contains a list of the guis that should be set exclusively.
	for _, screenGui in guiLayers do
		screenGui.Enabled = screenGui == enabledGui
	end
end

local function onSelectingBlaster()
	-- Movement is disabled upon spawning due to setting StarterPlayer properties
	-- CharacterWalkSpeed and CharacterJumpHeight to 0

	-- Enable the camera so players can look around while selecting a blaster
	togglePlayerCamera(true)
	setGuiExclusivelyEnabled(playerGui.PickABlasterGui)

	-- Disable blaster while selecting a blaster
	localPlayer:SetAttribute(PlayerAttribute.blasterStateClient, BlasterState.Disabled)
end

local function onPlaying()
	-- Enable player movement after picking a blaster
	togglePlayerMovement(true)
	setGuiExclusivelyEnabled(playerGui.HUDGui)

	-- Enable blaster while playing
	localPlayer:SetAttribute(PlayerAttribute.blasterStateClient, BlasterState.Ready)

	-- Schedule the destroy force field logic when the player begins playing
	scheduleDestroyForceField()
end

local function onTaggedOut()
	-- Disable controls while tagged out
	togglePlayerMovement(false)
	togglePlayerCamera(false)
	setGuiExclusivelyEnabled(playerGui.OutStateGui)

	-- Disable blaster while tagged out
	localPlayer:SetAttribute(PlayerAttribute.blasterStateClient, BlasterState.Disabled)
end

local function onPlayerStateChanged(newPlayerState: string)
	if newPlayerState == PlayerState.SelectingBlaster then
		onSelectingBlaster()
	elseif newPlayerState == PlayerState.Playing then
		onPlaying()
	elseif newPlayerState == PlayerState.TaggedOut then
		onTaggedOut()
	else
		warn(`Invalid player state ({newPlayerState})`)
	end
end

-- Handle the initial player state if set
local initialPlayerState = localPlayer:GetAttribute(PlayerAttribute.playerState)
onPlayerStateChanged(initialPlayerState)

-- Handle future player state updates
localPlayer:GetAttributeChangedSignal(PlayerAttribute.playerState):Connect(function()
	onPlayerStateChanged(localPlayer:GetAttribute(PlayerAttribute.playerState))
end)
