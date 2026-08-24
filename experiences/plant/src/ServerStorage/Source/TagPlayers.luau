--!strict

--[[
	Adds a CollectionService tag to all player and character objects
	Used by CollisionGroupManager to create components wrapped around Characters,
	and by ZoneHandler to check for characters in zones
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local PlayerTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PlayerTag)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)

local TagPlayers = {}

function TagPlayers.addTags(player: Player)
	CollectionService:AddTag(player, PlayerTag)

	local characterLoadedWrapper = PlayerObjectsContainer.getCharacterLoadedWrapper(player)

	if characterLoadedWrapper:isLoaded() then
		TagPlayers._onCharacterAdded(player.Character :: Model)
	end

	characterLoadedWrapper.loaded:Connect(function(character: any)
		TagPlayers._onCharacterAdded(character :: Model)
	end)
end

function TagPlayers._onCharacterAdded(character: Model)
	CollectionService:AddTag(character, CharacterTag.Character)
end

return TagPlayers
