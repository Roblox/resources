--!strict

--[[
	Handles the ReturningToFarm stage during the First Time User Experience,
	which waits for the player to return the wagon in their farm
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)

local ReturningToFarmFtueStage = {}

function ReturningToFarmFtueStage.handleAsync(player: Player): FtueStage.EnumType?
	while player.Character and CollectionService:HasTag(player.Character, CharacterTag.PullingWagon) do
		CollectionService:GetInstanceRemovedSignal(CharacterTag.PullingWagon):Wait()
	end

	return FtueStage.Complete
end

return ReturningToFarmFtueStage
