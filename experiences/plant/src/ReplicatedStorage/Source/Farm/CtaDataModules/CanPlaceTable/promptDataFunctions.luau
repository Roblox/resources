--!strict

--[[
	Defines ProximityPrompt functionality via callbacks for the CanPlaceTable cta
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)

local TABLE_ITEM_ID = "Table"

local RemoteEvents = Network.RemoteEvents

local promptDataFunctions = {
	getActionText = function()
		return PlayerFacingString.CallToAction.PlaceTable
	end,
	getObjectText = function(promptParent: Instance)
		return getAttribute(promptParent, Attribute.DisplayName) :: string
	end,
	onTriggered = function(promptParent: Instance)
		Network.fireServer(RemoteEvents.RequestPlaceObject, promptParent, TABLE_ITEM_ID)
	end,
}

return promptDataFunctions
