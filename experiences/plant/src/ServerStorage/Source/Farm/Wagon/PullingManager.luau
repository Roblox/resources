--!strict

--[[
	Server-side handling for pulling a wagon and attaching to/detaching from the character
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Source.Network)
local CollisionGroup = require(ServerStorage.Source.CollisionGroup)

local FollowingAttachment = require(ServerStorage.Source.FollowingAttachment)
local ZoneIdTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZoneIdTag)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local ContentsManager = require(ServerStorage.Source.Farm.Wagon.ContentsManager)
local Connections = require(ReplicatedStorage.Source.Connections)
local getFarmOwnerIdFromInstance = require(ReplicatedStorage.Source.Utility.Farm.getFarmOwnerIdFromInstance)
local getFarmModelFromOwnerId = require(ReplicatedStorage.Source.Utility.Farm.getFarmModelFromOwnerId)
local createInstanceTree = require(ReplicatedStorage.Source.Utility.createInstanceTree)
local playSmokePuff = require(ReplicatedStorage.Source.Utility.playSmokePuff)
local moveModelByAttachment = require(ReplicatedStorage.Source.Utility.moveModelByAttachment)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local RemoteEvents = Network.RemoteEvents
local t = Network.t

local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = CollisionGroup.Wagon

local followingAttachmentProperties: FollowingAttachment.FollowingAttachmentProperties = {
	maxFollowDistance = 7,
	verticalRayOffset = 3,
	downVectorDistance = 100,
	raycastParams = raycastParams,
}

local PullingManager = {}
PullingManager.__index = PullingManager

export type ClassType = typeof(setmetatable(
	{} :: {
		_wagonModel: Model,
		_contentsManager: ContentsManager.ClassType,
		_connections: Connections.ClassType,
		_alignPosition: AlignPosition?,
		_alignOrientation: AlignOrientation?,
		_wagonAttachment: Attachment,
		_followingAttachment: FollowingAttachment.ClassType?,
	},
	PullingManager
))

function PullingManager.new(wagonModel: Model, contentsManager: ContentsManager.ClassType): ClassType
	local wagonAttachment: Attachment = getInstance(wagonModel.PrimaryPart :: BasePart, "WagonAttachment")

	local self = {
		_wagonModel = wagonModel,
		_contentsManager = contentsManager,
		_connections = Connections.new(),
		_alignPosition = nil,
		_alignOrientation = nil,
		_wagonAttachment = wagonAttachment,
		_followingAttachment = nil,
	}

	assert(self._wagonAttachment, "No position attachment found in the PrimaryPart of " .. wagonModel:GetFullName())

	setmetatable(self, PullingManager)
	self:_listenForPullRequest()
	self:_listenForPlayerEnteredFarm()
	self:_listenForPlayerLeftFarm()

	return self
end

function PullingManager._listenForPullRequest(self: ClassType)
	local requestPullWagonConnection = Network.connectEvent(RemoteEvents.RequestPullWagon, function(player: Player)
		if not self:_canPull(player) then
			return
		end

		self:_onPullBegan(player)
	end, t.tuple(t.instanceOf("Player")))

	self._connections:add(requestPullWagonConnection)
end

function PullingManager._listenForPlayerEnteredFarm(self: ClassType)
	local farmZoneAddedSignal = CollectionService:GetInstanceAddedSignal(ZoneIdTag.InFarm)
	local farmZoneAddedConnection = farmZoneAddedSignal:Connect(function(instance: Instance)
		local character = instance :: Model

		-- Only listen to the owner's character entering their farm
		local player = Players:GetPlayerFromCharacter(character)
		if not player or not self:_canInteract(player) then
			return
		end

		if not CollectionService:HasTag(character, CharacterTag.PullingWagon) then
			return
		end

		-- Stop the pulling, teleport wagon inside
		self:_onPullEnded(player)
	end)

	self._connections:add(farmZoneAddedConnection)
end

function PullingManager._listenForPlayerLeftFarm(self: ClassType)
	local farmZoneRemovedSignal = CollectionService:GetInstanceRemovedSignal(ZoneIdTag.InFarm)
	local farmZoneRemovedConnection = farmZoneRemovedSignal:Connect(function(instance: Instance)
		-- Only listen to the owner's character leaving their farm
		local player = Players:GetPlayerFromCharacter(instance :: Model)
		if not player or not self:_canInteract(player) then
			return
		end

		-- Only begin pulling if they aren't already pulling
		local isPullingWagon = CollectionService:HasTag(player.Character :: Model, CharacterTag.PullingWagon)
		if isPullingWagon then
			return false
		end

		-- Begin pulling, teleport wagon to player
		self:_onPullBegan(player)
	end)

	self._connections:add(farmZoneRemovedConnection)
end

function PullingManager._canPull(self: ClassType, player: Player)
	if not self:_canInteract(player) then
		return false
	end

	local character = player.Character :: Model

	-- If this wagon is empty and in the farm, we don't want players to be able to move it
	local isInFarm = CollectionService:HasTag(character, ZoneIdTag.InFarm)
	if isInFarm and self._contentsManager:isEmpty() then
		return false
	end

	return true
end

function PullingManager._canInteract(self: ClassType, player: Player)
	if player.UserId ~= getFarmOwnerIdFromInstance(self._wagonModel) then
		return false
	end

	if not player.Character then
		return false
	end

	return true
end

function PullingManager._onPullBegan(self: ClassType, player: Player)
	local characterLoadedWrapper = PlayerObjectsContainer.getCharacterLoadedWrapper(player)

	if not characterLoadedWrapper:isLoaded() then
		return
	end
	local character = player.Character :: Model

	CollectionService:AddTag(character, CharacterTag.PullingWagon)
	self:_teleportWagonToPlayer(player)

	local humanoidDiedConnection
	humanoidDiedConnection = characterLoadedWrapper.died:Connect(function()
		-- This is a Signal class, not an RBXScriptConnection, so we do not need to worry about
		-- deferred Lua and are safe to disconnect this immediately
		humanoidDiedConnection:Disconnect()
		self._connections:remove(humanoidDiedConnection)
		self:_onPullEnded(player)
	end)
	self._connections:add(humanoidDiedConnection)
	self:_attachToPlayer(player)
end

function PullingManager._onPullEnded(self: ClassType, player: Player)
	local farm = getFarmModelFromOwnerId(player.UserId)
	assert(farm, "Farm does not exist")

	if player.Character then
		CollectionService:RemoveTag(player.Character :: Model, CharacterTag.PullingWagon)
	end

	self:_detachFromCharacter()

	local wagonAttachment: Attachment = getInstance(farm, "InsideWagonSpawn", "WagonAttachment")
	self:_teleportWagonToCFrame(wagonAttachment.WorldCFrame)
end

function PullingManager._teleportWagonToPlayer(self: ClassType, player: Player)
	assert(player.Character and player.Character.PrimaryPart, "Character does no exist")
	local farm = getFarmModelFromOwnerId(player.UserId)
	assert(farm, "Farm does not exist")

	local characterCFrame = player.Character.PrimaryPart.CFrame
	local outsidePlayerSpawn: Part = getInstance(farm, "OutsidePlayerSpawn")
	local outsideWagonSpawn: Part = getInstance(farm, "OutsideWagonSpawn")

	local wagonOffsetToPlayer = outsidePlayerSpawn.CFrame:ToObjectSpace(outsideWagonSpawn.CFrame)
	local spawnPosition: Vector3 = (characterCFrame * wagonOffsetToPlayer).Position
	local planarCharacterPosition = Vector3.new(characterCFrame.X, spawnPosition.Y, characterCFrame.Z)
	local pointingAtPlayerCFrame = CFrame.lookAt(spawnPosition, planarCharacterPosition)
	self:_teleportWagonToCFrame(pointingAtPlayerCFrame)
end

function PullingManager._teleportWagonToCFrame(self: ClassType, cframe: CFrame)
	local primaryPart = self._wagonModel.PrimaryPart :: BasePart
	playSmokePuff(primaryPart)

	local wagonAttachment: Attachment = getInstance(primaryPart, "WagonAttachment")
	moveModelByAttachment(self._wagonModel, wagonAttachment, cframe)
	playSmokePuff(primaryPart)
end

function PullingManager._attachToPlayer(self: ClassType, player: Player)
	assert(player.Character and player.Character.PrimaryPart, "Character does not exist")

	local followingAttachment = FollowingAttachment.new(player.Character, followingAttachmentProperties)
	local worldPositionAttachment = followingAttachment:getAttachment()
	self._followingAttachment = followingAttachment

	local primaryPart = player.Character.PrimaryPart

	local wagonPrimaryPart = self._wagonModel.PrimaryPart :: BasePart
	-- Wagons are anchored by default so they don't move around. Needs to be unanchored now so the player can pull it.
	wagonPrimaryPart.Anchored = false

	local alignPosition = createInstanceTree({
		className = "AlignPosition",
		properties = {
			Attachment0 = self._wagonAttachment,
			Attachment1 = worldPositionAttachment,
			MaxForce = 100000,
			Responsiveness = 25,
		},
	})
	alignPosition.Parent = primaryPart

	local alignOrientation = createInstanceTree({
		className = "AlignOrientation",
		properties = {
			Attachment0 = self._wagonAttachment,
			Attachment1 = worldPositionAttachment,
			MaxTorque = 100000,
			Responsiveness = 25,
		},
	})
	alignOrientation.Parent = primaryPart

	self._alignPosition = alignPosition
	self._alignOrientation = alignOrientation

	wagonPrimaryPart:SetNetworkOwner(player)
end

function PullingManager._detachFromCharacter(self: ClassType)
	if self._alignPosition then
		self._alignPosition:Destroy()
		self._alignPosition = nil
	end

	if self._alignOrientation then
		self._alignOrientation:Destroy()
		self._alignOrientation = nil
	end

	local primaryPart = self._wagonModel.PrimaryPart
	if primaryPart then
		if not primaryPart.Anchored then
			primaryPart:SetNetworkOwner(nil)
			primaryPart.Anchored = true
		end
	end

	local followingAttachmentMaybe = self._followingAttachment
	if followingAttachmentMaybe then
		local followingAttachment = followingAttachmentMaybe :: FollowingAttachment.ClassType
		followingAttachment:destroy()
	end
end

function PullingManager.destroy(self: ClassType)
	self:_detachFromCharacter()
	self._connections:disconnect()
end

return PullingManager
