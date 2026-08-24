--!strict

--[[
	Defines ProximityPrompt functionality via callbacks for the CanHarvest cta
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Network = require(ReplicatedStorage.Source.Network)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local RemoteEvents = Network.RemoteEvents

local harvestSound: Sound = getInstance(SoundService, "SoundEffects", "Harvest")

local promptDataFunctions = {
	getActionText = function(promptParent: Instance)
		return PlayerFacingString.CallToAction.HarvestPlant
	end,

	getObjectText = function(promptParent: Instance)
		return getAttribute(promptParent, Attribute.DisplayName) :: string
	end,

	onTriggered = function(promptParent: Instance)
		harvestSound:Play()

		local plantModel = promptParent
		Network.fireServer(RemoteEvents.PlantHarvested, plantModel)
	end,
}

return promptDataFunctions
