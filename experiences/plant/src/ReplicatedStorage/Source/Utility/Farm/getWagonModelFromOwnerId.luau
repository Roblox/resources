--!strict

--[[
	Returns the wagon model in workspace belonging to a player with a user ID
	matching the given ownerId. This is based on the OwnerId attribute of farm
	models, which gets set by the server when the farm is loaded for a player.

	The Wagon is identified by the Wagon CollectionService tag.
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WagonTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.WagonTag)
local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local getFarmModelFromOwnerId = require(ReplicatedStorage.Source.Utility.Farm.getFarmModelFromOwnerId)

local function getWagonModelFromOwnerId(ownerId: number): Model?
	local maybeFarm = getFarmModelFromOwnerId(ownerId)

	if not maybeFarm then
		return nil
	end

	local farm = maybeFarm :: Model

	local wagons = Freeze.List.filter(farm:GetChildren(), function(instance: Instance)
		return CollectionService:HasTag(instance, WagonTag.Wagon)
	end)

	-- At most, only one wagon will exist matching in a farm, so it's safe to grab the first list item
	return wagons[1] :: Model
end

return getWagonModelFromOwnerId
