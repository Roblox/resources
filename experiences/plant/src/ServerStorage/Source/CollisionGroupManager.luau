--!strict

--[[
	Creates and configures collision groups.
	Used to prevent characters from colliding with wagons.
--]]

local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DescendantsCollisionGroup = require(ServerStorage.Source.DescendantsCollisionGroup)
local ComponentCreator = require(ReplicatedStorage.Source.ComponentCreator)
local CollisionGroup = require(ServerStorage.Source.CollisionGroup)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)

local CollisionGroupManager = {}

function CollisionGroupManager.start()
	PhysicsService:RegisterCollisionGroup(CollisionGroup.Character)
	PhysicsService:RegisterCollisionGroup(CollisionGroup.Wagon)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroup.Character, CollisionGroup.Wagon, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroup.Wagon, CollisionGroup.Wagon, false)

	-- DescendantsCollisionGroup.new() will be called with the Character model, CollisionGroup.Character as the arguments
	ComponentCreator.new(CharacterTag.Character, DescendantsCollisionGroup, CollisionGroup.Character):listen()
end

return CollisionGroupManager
