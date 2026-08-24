--!strict

--[[
	Defines ProximityPrompt visibility logic specific to the CanRemove cta
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)

local localPlayer = Players.LocalPlayer :: Player

local function shouldEnable(promptParent: Instance)
	-- Can't remove a pot while holding another plant
	-- If Character doesn't exist, HasTag() returns false, so this still works correctly without waiting for character loaded
	local character = localPlayer.Character
	if not character then
		return false
	end

	local isHoldingPlant = CollectionService:HasTag(character :: Model, CharacterTag.Holding)
	if isHoldingPlant then
		return false
	end

	if UIHandler.areMenusVisible() then
		return false
	end

	return true
end

return shouldEnable
