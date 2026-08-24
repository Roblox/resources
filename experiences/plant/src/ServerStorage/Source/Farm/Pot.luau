--!strict

--[[
	Class associated with a pot instance that provides serialization & deserialization.
	This also handles client-side planting and harvesting mechanics.
--]]

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Plant = require(ServerStorage.Source.Farm.Plant)
local CustomAnalytics = require(ServerStorage.Source.Analytics.CustomAnalytics)
local Network = require(ReplicatedStorage.Source.Network)
local Signal = require(ReplicatedStorage.Source.Signal)
local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local PotTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PotTag)
local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local Connections = require(ReplicatedStorage.Source.Connections)
local getFarmOwnerIdFromInstance = require(ReplicatedStorage.Source.Utility.Farm.getFarmOwnerIdFromInstance)
local weldDescendantsToPrimaryPart = require(ReplicatedStorage.Source.Utility.weldDescendantsToPrimaryPart)
local moveModelByAttachment = require(ReplicatedStorage.Source.Utility.moveModelByAttachment)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local rigidlyAttach = require(ReplicatedStorage.Source.Utility.rigidlyAttach)
local checkSeedFitsInPot = require(ReplicatedStorage.Source.Utility.Farm.checkSeedFitsInPot)
local getPlantIdFromSeedId = require(ReplicatedStorage.Source.Utility.Farm.getPlantIdFromSeedId)
local getSeedIdFromPlantId = require(ReplicatedStorage.Source.Utility.Farm.getSeedIdFromPlantId)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local t = Network.t

export type PotData = {
	plant: Plant.PlantData?,
	id: string,
}

local Pot = {}
Pot.__index = Pot

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Model,
		_id: string,
		_plant: Plant.ClassType?,
		_plantChangedConnection: Signal.SignalConnection?,
		_plantHarvestedConnection: Signal.SignalConnection?,
		_connections: Connections.ClassType,
		changed: Signal.ClassType,
		removeRequested: Signal.ClassType,
	},
	Pot
))

function Pot.new(potData: PotData): ClassType
	local potPrefab: Model? = getItemByIdInCategory(potData.id, ItemCategory.Pots)
	assert(potPrefab, string.format("Unable to find %s in Pots container", potData.id))

	local self = {
		_instance = potPrefab:Clone(),
		_id = potData.id,
		_plant = nil,
		_plantChangedConnection = nil,
		_plantHarvestedConnection = nil,
		_connections = Connections.new(),
		changed = Signal.new(),
		removeRequested = Signal.new(),
	}

	setmetatable(self, Pot)
	self:_loadData(potData)
	self:_listenForPlantRequest()
	self:_listenForRemoveRequest()

	return self
end

function Pot.getData(self: ClassType)
	local plantData = if self._plant then self._plant:getData() else nil

	local data: PotData = {
		plant = plantData,
		id = self._id,
	}

	return data
end

function Pot._listenForPlantRequest(self: ClassType)
	local plantRequestConnection = Network.connectEvent(
		Network.RemoteEvents.RequestPlantSeed,
		function(player: Player, pot: Model, seedId: string)
			if pot == self._instance then
				self:_onPlantRequest(player, seedId)
			end
		end,
		t.tuple(t.instanceOf("Player"), t.instanceOf("Model"), t.string)
	)
	self._connections:add(plantRequestConnection)
end

function Pot._listenForRemoveRequest(self: ClassType)
	local removeRequestConnection = Network.connectEvent(
		Network.RemoteEvents.RequestRemoveObject,
		function(player: Player, pot: Model)
			if pot == self._instance then
				if not self:_canRemove(player) then
					return
				end

				self.removeRequested:Fire()
			end
		end,
		t.tuple(t.instanceOf("Player"), t.instanceOf("Model"))
	)

	self._connections:add(removeRequestConnection)
end

function Pot._canRemove(self: ClassType, player: Player)
	if player.UserId ~= getFarmOwnerIdFromInstance(self._instance) then
		return false
	end

	if not self._instance:HasTag(PotTag.CanRemove) then
		return false
	end

	return true
end

function Pot._canPlantSeed(self: ClassType, player: Player, seedId: string)
	local ownerId = getFarmOwnerIdFromInstance(self._instance)
	local ownerPlayer = Players:GetPlayerByUserId(ownerId)

	-- You can only plant seeds in your own pot
	if player ~= ownerPlayer then
		return false
	end

	-- You cannot plant if there is already a plant in this pot
	if self._plant then
		return false
	end

	-- You can only plant seeds that exist
	local success = pcall(getItemByIdInCategory, seedId, ItemCategory.Seeds)
	if not success then
		return false
	end

	-- You cannot plant a plant that is bigger than the pot allows
	if not checkSeedFitsInPot(seedId, self._id) then
		return false
	end

	-- You cannot plant if you don't have enough seeds
	local inventory = PlayerDataServer.getValue(player, PlayerDataKey.Inventory)
	local seedCountById = inventory[ItemCategory.Seeds]
	local seedCount = seedCountById and seedCountById[seedId] or 0
	if seedCount <= 0 then
		return false
	end

	return true
end

function Pot._onPlantRequest(self: ClassType, player: Player, seedId: string)
	if not self:_canPlantSeed(player, seedId) then
		return
	end

	local plantId = getPlantIdFromSeedId(seedId)

	PlayerDataServer.updateValue(player, PlayerDataKey.Inventory, function(
		inventory: {
			[string]: { -- [category]: countByItemId
				[string]: number, -- [itemId]: count
			},
		}
	)
		local seedCountById = inventory[ItemCategory.Seeds]
		seedCountById[seedId] -= 1

		return inventory
	end)

	CustomAnalytics.logSeedPlanted(player, self._id, seedId)

	self:_addPlant({
		id = plantId,
		currentStage = 1,
		timeGrown = 0,
	})
end

function Pot._addPlant(self: ClassType, plantData: Plant.PlantData)
	local plant = Plant.new(plantData)
	self._plant = plant

	self._plantChangedConnection = plant.changed:Connect(function()
		self.changed:Fire()
	end)

	self._plantHarvestedConnection = plant.harvested:Connect(function()
		self:_onPlantHarvested()
	end)

	local plantAttachment: Attachment = getInstance(self._instance.PrimaryPart :: BasePart, "PlantAttachment")
	local contents: Folder = getInstance(self._instance, "Contents")

	plant:attachTo(plantAttachment)
	plant:getInstance().Parent = contents

	CollectionService:RemoveTag(self._instance, PotTag.CanRemove)
	CollectionService:RemoveTag(self._instance, PotTag.CanPlant)
	self.changed:Fire()
end

function Pot._loadData(self: ClassType, potData: PotData)
	weldDescendantsToPrimaryPart(self._instance)

	if potData.plant then
		self:_addPlant(potData.plant)
	else
		CollectionService:AddTag(self._instance, PotTag.CanRemove)
		CollectionService:AddTag(self._instance, PotTag.CanPlant)
	end
end

function Pot._onPlantHarvested(self: ClassType)
	assert(self._plant, "Cannot call _onPlantHarvested on a pot with no plant")
	-- Pick up harvested plant
	local plantId = self._plant:getId()
	local ownerId = getFarmOwnerIdFromInstance(self._instance)
	local player = Players:GetPlayerByUserId(ownerId)

	local playerPickupHandler = PlayerObjectsContainer.getPlayerPickupHandler(player)

	if playerPickupHandler:isHolding() then
		return
	end

	playerPickupHandler:startHolding(plantId)

	-- Grant 1 seed of the same kind harvested to avoid the player getting soft locked if they run out of money
	PlayerDataServer.updateValue(player, PlayerDataKey.Inventory, function(
		inventory: {
			[string]: { -- [category]: countByItemId
				[string]: number, -- [itemId]: count
			},
		}
	)
		local seedId = getSeedIdFromPlantId(plantId)
		local seedCountById = inventory[ItemCategory.Seeds]
		local itemCount = seedCountById[seedId] or 0
		itemCount += 1

		seedCountById[seedId] = itemCount

		return inventory
	end)

	-- Destroy potted plant
	self:_destroyPlant()
	self.changed:Fire()
end

function Pot.movePrimaryAttachmentTo(self: ClassType, targetCFrame: CFrame)
	local potAttachment: Attachment = getInstance(self._instance.PrimaryPart :: BasePart, "PotAttachment")
	moveModelByAttachment(self._instance, potAttachment, targetCFrame)
end

function Pot.attachTo(self: ClassType, targetAttachment: Attachment)
	local potAttachment: Attachment = getInstance(self._instance.PrimaryPart :: BasePart, "PotAttachment")
	rigidlyAttach(targetAttachment, potAttachment)
end

function Pot.getInstance(self: ClassType)
	return self._instance
end

function Pot.getId(self: ClassType)
	return self._id
end

function Pot._destroyPlant(self: ClassType)
	if self._plantChangedConnection then
		self._plantChangedConnection:Disconnect()
		self._plantChangedConnection = nil
	end

	if self._plantHarvestedConnection then
		self._plantHarvestedConnection:Disconnect()
		self._plantHarvestedConnection = nil
	end

	if self._plant then
		self._plant:destroy()
		self._plant = nil
	end

	CollectionService:AddTag(self._instance, PotTag.CanRemove)
	CollectionService:AddTag(self._instance, PotTag.CanPlant)
end

function Pot.destroy(self: ClassType)
	self:_destroyPlant()
	self._connections:disconnect()
	self._instance:Destroy()
	self.changed:DisconnectAll()
	self.removeRequested:DisconnectAll()
end

return Pot
