--!strict

--[[
	Creates pickup model prefabs for each plant type at runtime. These models are used
	while a player is holding a plant.

	Can be used by other scripts to get any pickup prefab by plant id.
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)
local createHarvestedPlantModel = require(ServerStorage.Source.Farm.createHarvestedPlantModel)

local plantsFolder: Folder = getInstance(ReplicatedStorage, "Instances", "Plants")

local PickupPrefabsById = {}

-- Harvested plant pickups
for _, plantPrefab in ipairs(plantsFolder:GetChildren()) do
	PickupPrefabsById[plantPrefab.Name] = createHarvestedPlantModel(plantPrefab.Name)
end

return PickupPrefabsById
