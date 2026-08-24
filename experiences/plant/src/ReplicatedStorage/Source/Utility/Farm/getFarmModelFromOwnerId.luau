--!strict

--[[
	Returns the farm model in workspace belonging to a player with a user ID
	matching the given ownerId. This is based on the OwnerId attribute of farm
	models, which gets set by the server when the farm is loaded for a player.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmConstants = require(ReplicatedStorage.Source.Farm.FarmConstants)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local Freeze = require(ReplicatedStorage.Dependencies.Freeze)

local function getFarmModelFromOwnerId(ownerId: number): Model?
	local farms = Freeze.List.filter(FarmConstants.FarmContainer:GetChildren(), function(instance: Instance)
		return instance:GetAttribute(Attribute.OwnerId) == ownerId
	end)

	-- At most, only one farm will exist matching the ownerId, so it's safe to grab the first list item
	local farm = farms[1]
	if farm then
		assert(farm:IsA("Model"), "Farm is not a Model")
		return farm
	end

	return nil
end

return getFarmModelFromOwnerId
