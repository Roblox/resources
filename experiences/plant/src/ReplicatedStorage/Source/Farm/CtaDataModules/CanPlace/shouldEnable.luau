--!strict

--[[
	Defines ProximityPrompt visibility logic specific to the CanPlace cta
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local WagonTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.WagonTag)

local localPlayer = Players.LocalPlayer :: Player

local function shouldEnable(promptParent: Instance)
	local character = localPlayer.Character
	if not character then
		return false
	end

	-- Can't place something you're not carrying
	local isHoldingPlant = CollectionService:HasTag(character :: Model, CharacterTag.Holding)
	if not isHoldingPlant then
		return false
	end

	-- Can't overfill the wagon
	local wagon = promptParent
	local isWagonFull = CollectionService:HasTag(wagon, WagonTag.WagonFull)
	if isWagonFull then
		return false
	end

	return true
end

return shouldEnable
