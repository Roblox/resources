--!strict

--[[
	Creates a harvested plant model based on the given plantId
	Since stages and the Harvested model are stored in the same Plant prefab,
	the stages must be removed for the final Harvested model.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)

local weldDescendantsToPrimaryPart = require(ReplicatedStorage.Source.Utility.weldDescendantsToPrimaryPart)
local rigidlyAttach = require(ReplicatedStorage.Source.Utility.rigidlyAttach)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

return function(plantId: string)
	local plantPrefab: Model = getItemByIdInCategory(plantId, ItemCategory.Plants)
	local instance: Model = plantPrefab:Clone()
	local stagesFolder: Folder = getInstance(instance, "Stages")
	stagesFolder:Destroy()

	local harvestedModel: Model = getInstance(instance, "Harvested")
	weldDescendantsToPrimaryPart(harvestedModel)

	local plantPrimaryPart = instance.PrimaryPart :: BasePart
	local harvestedModelPrimaryPart = harvestedModel.PrimaryPart :: BasePart
	local primaryAttachment: Attachment = getInstance(plantPrimaryPart, "PlantAttachment")
	local secondaryAttachment: Attachment = getInstance(harvestedModelPrimaryPart, "PlantAttachment")
	rigidlyAttach(primaryAttachment, secondaryAttachment)

	return instance
end
