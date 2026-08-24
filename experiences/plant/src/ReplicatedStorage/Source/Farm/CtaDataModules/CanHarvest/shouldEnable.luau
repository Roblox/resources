--!strict

--[[
	Defines ProximityPrompt visibility logic specific to the CanHarvest cta
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local WagonTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.WagonTag)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)

local getWagonModelFromOwnerId = require(ReplicatedStorage.Source.Utility.Farm.getWagonModelFromOwnerId)
local localPlayer = Players.LocalPlayer :: Player

local function shouldEnable(promptParent: Instance)
	local wagonMaybe = getWagonModelFromOwnerId(localPlayer.UserId)
	if not wagonMaybe then
		-- Wagon doesn't exist, which only happens during the first FTUE stage.
		-- Harvesting triggers the next stage, so we allow harvesting without the wagon.
		return true
	end
	local wagon = wagonMaybe :: Model

	-- If wagon or Character doesn't exist, HasTag() returns false, so this still works correctly
	local isWagonFull = CollectionService:HasTag(wagon, WagonTag.WagonFull)

	local character = localPlayer.Character
	if not character then
		return false
	end

	if UIHandler.areMenusVisible() then
		return false
	end

	local isHoldingPlant = CollectionService:HasTag(character :: Model, CharacterTag.Holding)

	-- Can't carry multiple plants
	if isHoldingPlant then
		return false
	end

	-- Don't want the player to be stuck holding a plant they can't place
	if isWagonFull then
		return false
	end

	return true
end

return shouldEnable
