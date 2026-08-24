--!strict

--[[
	Defines ProximityPrompt functionality via callbacks for the NeedsWater cta
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Network = require(ReplicatedStorage.Source.Network)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local RemoteEvents = Network.RemoteEvents

local waterSoundEffect: Sound = getInstance(SoundService, "SoundEffects", "Water")

local promptDataFunctions = {
	getActionText = function(promptParent: Instance)
		return PlayerFacingString.CallToAction.WaterPlant
	end,
	getObjectText = function(promptParent: Instance)
		return getAttribute(promptParent, Attribute.DisplayName) :: string
	end,
	onTriggered = function(promptParent: Instance)
		waterSoundEffect:Play()

		local plantModel = promptParent
		Network.fireServer(RemoteEvents.PlantWatered, plantModel)
	end,
}

return promptDataFunctions
