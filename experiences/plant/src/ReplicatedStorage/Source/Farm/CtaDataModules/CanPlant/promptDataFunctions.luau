--!strict

--[[
	Defines ProximityPrompt functionality via callbacks for the CanPlant cta
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UIPlantSeed = require(ReplicatedStorage.Source.UI.UILayers.UIPlantSeed)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)

local promptDataFunctions = {
	getActionText = function()
		return PlayerFacingString.CallToAction.PlantSeed
	end,
	getObjectText = function(promptParent: Instance)
		return getAttribute(promptParent, Attribute.DisplayName) :: string
	end,
	onTriggered = function(promptParent: Instance)
		UIPlantSeed.setPotModel(promptParent :: Model)
		UIHandler.show(UILayerId.PlantSeed)
	end,
}

return promptDataFunctions
