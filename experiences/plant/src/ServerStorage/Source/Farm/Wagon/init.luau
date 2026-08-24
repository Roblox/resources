--!strict

--[[
	Class associated with a wagon instance that provides serialization & deserialization,
	event triggering based on wagon position, and components for pulling and contents.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Signal = require(ReplicatedStorage.Source.Signal)
local Market = require(ServerStorage.Source.Market)
local ContentsManager = require(ServerStorage.Source.Farm.Wagon.ContentsManager)
local PullingManager = require(ServerStorage.Source.Farm.Wagon.PullingManager)
local DescendantsCollisionGroup = require(ServerStorage.Source.DescendantsCollisionGroup)
local CollisionGroup = require(ServerStorage.Source.CollisionGroup)
local WagonTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.WagonTag)
local ZoneIdTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZoneIdTag)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local Connections = require(ReplicatedStorage.Source.Connections)
local weldDescendantsToPrimaryPart = require(ReplicatedStorage.Source.Utility.weldDescendantsToPrimaryPart)
local moveModelByAttachment = require(ReplicatedStorage.Source.Utility.moveModelByAttachment)
local getFarmOwnerIdFromInstance = require(ReplicatedStorage.Source.Utility.Farm.getFarmOwnerIdFromInstance)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

export type WagonData = {
	id: string,
	contents: { string }, -- array of plant ids
}

local Wagon = {}
Wagon.__index = Wagon

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Model,
		_connections: Connections.ClassType,
		_contentsManager: ContentsManager.ClassType,
		_pullingManager: PullingManager.ClassType,
		_descendantsCollisionGroup: DescendantsCollisionGroup.ClassType,
		changed: Signal.ClassType,
	},
	Wagon
))

function Wagon.new(wagonData: WagonData): ClassType
	local wagonPrefab = getItemByIdInCategory(wagonData.id, ItemCategory.Wagons)
	assert(wagonPrefab, string.format("Unable to find %s in Wagons container", wagonData.id))

	local instance = wagonPrefab:Clone()
	local contentsManger = ContentsManager.new(instance, wagonData.contents)
	local pullingManager = PullingManager.new(instance, contentsManger)
	local descendantsCollisionGroup = DescendantsCollisionGroup.new(instance, CollisionGroup.Wagon)

	local self = {
		_instance = instance,
		_connections = Connections.new(),
		_contentsManager = contentsManger,
		_pullingManager = pullingManager,
		_descendantsCollisionGroup = descendantsCollisionGroup,
		changed = Signal.new(),
	}

	setmetatable(self, Wagon)

	self:_setup()

	return self
end

function Wagon._setup(self: ClassType)
	local primaryPart = self._instance.PrimaryPart :: BasePart
	primaryPart.Anchored = true

	weldDescendantsToPrimaryPart(self._instance)

	CollectionService:AddTag(self._instance, WagonTag.Wagon)
	CollectionService:AddTag(self._instance, WagonTag.CanPlace)

	self:_listenForContentsChanged()
	self:_listenForMarketEntered()
end

function Wagon.getData(self: ClassType)
	local data: WagonData = {
		id = self._instance.Name,
		contents = self._contentsManager:getPlantIds(),
	}

	return data
end

function Wagon.getContentsManager(self: ClassType)
	return self._contentsManager
end

function Wagon._listenForContentsChanged(self: ClassType)
	local contentsChangedConnection = self._contentsManager.changed:Connect(function()
		self.changed:Fire()
	end)
	self._connections:add(contentsChangedConnection)
end

function Wagon._listenForMarketEntered(self: ClassType)
	local instanceAddedSignal = CollectionService:GetInstanceAddedSignal(ZoneIdTag.InMarket)

	local inMarketConnection = instanceAddedSignal:Connect(function(instance: Instance)
		local player = Players:GetPlayerFromCharacter(instance :: Model)
		if not player then
			return
		end

		if not self:_canEnterMarket(player) then
			return
		end

		self:_onMarketEntered()
	end)

	self._connections:add(inMarketConnection)
end

function Wagon._canEnterMarket(self: ClassType, player: Player)
	-- Only listen to the owner of this wagon
	local ownerId = getFarmOwnerIdFromInstance(self._instance)
	if ownerId ~= player.UserId then
		return false
	end

	if not player.Character then
		return false
	end

	-- Only listen while the player is holding the wagon
	if not CollectionService:HasTag(player.Character :: Model, CharacterTag.PullingWagon) then
		return false
	end

	return true
end

function Wagon._onMarketEntered(self: ClassType)
	local ownerId = getFarmOwnerIdFromInstance(self._instance)

	local player = Players:GetPlayerByUserId(ownerId)
	if not player then
		-- Player left the game
		return
	end

	local plantIds = self._contentsManager:getPlantIds()

	self._contentsManager:clearContents()
	Market.sellPlants(player, plantIds)
end

function Wagon.movePrimaryAttachmentTo(self: ClassType, targetCFrame: CFrame)
	local wagonAttachment: Attachment = getInstance(self._instance.PrimaryPart :: BasePart, "WagonAttachment")
	moveModelByAttachment(self._instance, wagonAttachment, targetCFrame)
end

function Wagon.getInstance(self: ClassType)
	return self._instance
end

function Wagon.getPullingManager(self: ClassType)
	return self._pullingManager
end

function Wagon.destroy(self: ClassType)
	self.changed:DisconnectAll()
	self._connections:disconnect()
	self._contentsManager:destroy()
	self._pullingManager:destroy()
	self._descendantsCollisionGroup:destroy()
	self._instance:Destroy()
end

return Wagon
