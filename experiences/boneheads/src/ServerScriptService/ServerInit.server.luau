local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Systems = ServerScriptService.Systems

local AimServer = require(ReplicatedStorage.Systems.Aim.AimServer)
local AudioServer = require(ServerScriptService.Systems.Audio.AudioServer)
local ClothingColliders = require(Systems.CustomAbilities.ClothingColliders)
local Collision = require(ReplicatedStorage.Systems.Collision.Collision)
local CustomAvatarSpawner = require(Systems.Spawn.CustomAvatarSpawner)
local DeathPlane = require(Systems.DeathPlane.DeathPlane)
local DisableDefaultAbilities = require(Systems.CustomAbilities.DisableDefaultAbilities)
local HeadSpawner = require(Systems.Spawn.HeadSpawner)
local KnockOff = require(Systems.KnockOff.KnockOff)
local LimbScaler = require(Systems.Spawn.LimbScaler.LimbScaler)
local SkeletonTint = require(Systems.Spawn.SkeletonTint.SkeletonTint)

local MechanismSystem = require(Systems.MechanismSystem.MechanismSystem)
local MechanismDefinitions = ServerScriptService.Systems.MechanismSystem.Definitions
local SoundDefinitions = ReplicatedStorage.Systems.Audio.SoundDefinitions

local moveAssets = require(ServerScriptService.Utility.moveAssets)

local function initialize()
	MechanismSystem.autoLoad(MechanismDefinitions)
	AudioServer.loadDefinitions(SoundDefinitions)

	moveAssets()

	AimServer.start()
	ClothingColliders.start()
	HeadSpawner.start()
	CustomAvatarSpawner.start()
	Collision.start()
	KnockOff.start()
	DisableDefaultAbilities.start()
	LimbScaler.start()
	SkeletonTint.start()
	DeathPlane.start()
	MechanismSystem.start()
end

initialize()
