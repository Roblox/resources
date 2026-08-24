--!strict

--[[
	Defines ProximityPrompt functionality via callbacks for the CanPlace cta
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Network = require(ReplicatedStorage.Source.Network)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local RemoteEvents = Network.RemoteEvents

local wagonPlace: Sound = getInstance(SoundService, "SoundEffects", "WagonPlace")

local promptDataFunctions = {
	getActionText = function()
		return PlayerFacingString.CallToAction.PlacePlant
	end,
	getObjectText = function(promptParent: Instance)
		return getAttribute(promptParent, Attribute.DisplayName) :: string
	end,
	onTriggered = function(promptParent: Instance)
		wagonPlace:Play()

		Network.fireServer(RemoteEvents.PlantPlaced)
	end,
}

return promptDataFunctions
