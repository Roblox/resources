--!strict

--[[
	Defines ProximityPrompt functionality via callbacks for the CanRemove cta
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Network = require(ReplicatedStorage.Source.Network)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local RemoteEvents = Network.RemoteEvents

local removeObjectSound: Sound = getInstance(SoundService, "SoundEffects", "RemoveObject")

local promptDataFunctions = {
	getActionText = function()
		return PlayerFacingString.CallToAction.RemovePot
	end,
	getObjectText = function(promptParent: Instance)
		return getAttribute(promptParent, Attribute.DisplayName) :: string
	end,
	onTriggered = function(promptParent: Instance)
		removeObjectSound:Play()

		local potModel = promptParent
		Network.fireServer(RemoteEvents.RequestRemoveObject, potModel)
	end,
}

return promptDataFunctions
