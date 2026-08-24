--!strict

--[[
	Defines ProximityPrompt functionality via callbacks for the CanPlacePot cta
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UIPlacePot = require(ReplicatedStorage.Source.UI.UILayers.UIPlacePot)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)

local promptDataFunctions = {
	getActionText = function()
		return PlayerFacingString.CallToAction.PlacePot
	end,
	getObjectText = function(promptParent: Instance)
		return getAttribute(promptParent, Attribute.DisplayName) :: string
	end,
	onTriggered = function(promptParent: Instance)
		UIPlacePot.setSpotModel(promptParent :: Model)
		UIHandler.show(UILayerId.PlacePot)
	end,
}

return promptDataFunctions
