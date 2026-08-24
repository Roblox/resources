--!strict

--[[
	Class associated with a table instance that provides serialization & deserialization
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local Pot = require(ServerStorage.Source.Farm.Pot)
local Signal = require(ReplicatedStorage.Source.Signal)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local PlaceableArea = require(ServerStorage.Source.Farm.PlaceableArea)
local PlacementTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PlacementTag)
local getFarmOwnerIdFromInstance = require(ReplicatedStorage.Source.Utility.Farm.getFarmOwnerIdFromInstance)
local moveModelByAttachment = require(ReplicatedStorage.Source.Utility.moveModelByAttachment)
local weldDescendantsToPrimaryPart = require(ReplicatedStorage.Source.Utility.weldDescendantsToPrimaryPart)
local rigidlyAttach = require(ReplicatedStorage.Source.Utility.rigidlyAttach)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local TABLE_ITEM_ID = "Table"
local validItemPlacementIds = getSortedIdsInCategory(ItemCategory.Pots)
local tablePrefab = getItemByIdInCategory(TABLE_ITEM_ID, ItemCategory.Tables)

export type TableData = {
	id: string,
	pots: { [string]: Pot.PotData? },
}

local Table = {}
Table.__index = Table

export type ClassType = typeof(setmetatable(
	{} :: {
		_id: string,
		_instance: Model,
		_pots: { [string]: Pot.ClassType },
		_placeableAreas: { [string]: PlaceableArea.ClassType },
		changed: Signal.ClassType,
	},
	Table
))

function Table.new(tableData: TableData): ClassType
	local self = {
		_id = tableData.id,
		_instance = tablePrefab:Clone(),
		_pots = {},
		_placeableAreas = {},
		changed = Signal.new(),
	}

	setmetatable(self, Table)
	self:_loadData(tableData)

	return self
end

function Table.getData(self: ClassType)
	local potsData = Freeze.Dictionary.map(self._pots, function(pot: Pot.ClassType, spotKey: string)
		return pot:getData(), spotKey
	end)

	local data: TableData = {
		id = self._id,
		pots = potsData,
	}

	return data
end

function Table._getSpotModel(self: ClassType, spotNumber: number)
	local potSpots: Folder = getInstance(self._instance, "PotSpots")
	local potModelMaybe: Instance? = potSpots:FindFirstChild("Spot" .. spotNumber)
	return potModelMaybe :: Model?
end

function Table._getNumberOfSpots(self: ClassType)
	local numberOfSpots = 0

	while self:_getSpotModel(numberOfSpots + 1) do
		numberOfSpots += 1
	end

	return numberOfSpots
end

function Table._createPlaceablePotArea(self: ClassType, spotNumber: number)
	local spotKey = self:_getKeyForSpotNumber(spotNumber)
	local spotModel = self:_getSpotModel(spotNumber)
	assert(spotModel, string.format("Spot model does not exist for number %d", spotNumber))

	local placeableArea = PlaceableArea.new(spotModel, validItemPlacementIds, PlacementTag.CanPlacePot)

	-- This connection gets disconnected when placeableArea gets destroyed
	placeableArea.placeRequested:Connect(function(_: any, itemId: any)
		self._placeableAreas[spotKey] = nil
		placeableArea:destroy()
		self._pots[spotKey] = self:_createPotAt(spotNumber, {
			plant = nil,
			id = itemId :: string,
		})
	end)
	self._placeableAreas[spotKey] = placeableArea
end

function Table._loadData(self: ClassType, tableData: TableData)
	weldDescendantsToPrimaryPart(self._instance)

	-- Using a dictionary instead of array to allow pots to be placed in any order (spot1 = potA, spot2 = nil, spot3 = potB)
	for spotNumber = 1, self:_getNumberOfSpots() do
		local spotKey = self:_getKeyForSpotNumber(spotNumber)
		local potData: Pot.PotData? = tableData.pots[spotKey]

		if potData then
			self._pots[spotKey] = self:_createPotAt(spotNumber, potData)
		else
			self:_createPlaceablePotArea(spotNumber)
		end
	end
end

function Table._getKeyForSpotNumber(self: ClassType, spotNumber: number): string
	return "spot" .. tostring(spotNumber)
end

function Table._createPotAt(self: ClassType, potNumber: number, potData: Pot.PotData)
	local potSpotModel = self:_getSpotModel(potNumber)
	assert(potSpotModel, "Cannot create a pot at a spot that doesn't exist")

	local pot = Pot.new(potData)

	-- These connections get disconnected when the pot is destroyed
	pot.changed:Connect(function()
		self.changed:Fire()
	end)
	pot.removeRequested:Connect(function()
		self:_removePotAt(potNumber)
	end)

	local potAttachment: Attachment = getInstance(potSpotModel.PrimaryPart :: BasePart, "PotAttachment")
	local contents: Model = getInstance(potSpotModel, "Contents")

	pot:attachTo(potAttachment)
	pot:getInstance().Parent = contents

	-- Deferred to give a chance for the caller to use the return value and update data before listeners activate
	task.defer(self.changed.Fire, self.changed)

	return pot
end

function Table._removePotAt(self: ClassType, potNumber: number)
	local spotKey = self:_getKeyForSpotNumber(potNumber)
	local pot = self._pots[spotKey]
	assert(pot, `Cannot remove pot at spot ${potNumber} because it doesn't exist`)
	local playerId = getFarmOwnerIdFromInstance(self._instance)
	local player = Players:GetPlayerByUserId(playerId)

	PlayerDataServer.updateValue(player, PlayerDataKey.Inventory, function(
		inventory: {
			[string]: { -- [category]: countByItemId
				[string]: number, -- [itemId]: count
			},
		}
	)
		local potCountById = inventory[ItemCategory.Pots]
		local itemCount = potCountById[pot:getId()] or 0
		itemCount += 1

		potCountById[pot:getId()] = itemCount

		return inventory
	end)

	pot:destroy()
	self._pots[spotKey] = nil

	self:_createPlaceablePotArea(potNumber)
	self.changed:Fire()
end

function Table.movePrimaryAttachmentTo(self: ClassType, targetCFrame: CFrame)
	local tableAttachment: Attachment = getInstance(self._instance.PrimaryPart :: BasePart, "TableAttachment")
	moveModelByAttachment(self._instance, tableAttachment, targetCFrame)
end

function Table.attachTo(self: ClassType, targetAttachment: Attachment)
	local tableAttachment: Attachment = getInstance(self._instance.PrimaryPart :: BasePart, "TableAttachment")
	rigidlyAttach(targetAttachment, tableAttachment)
end

function Table.getInstance(self: ClassType)
	return self._instance
end

function Table.destroy(self: ClassType)
	for _, placeableArea in pairs(self._placeableAreas) do
		placeableArea:destroy()
	end

	for _, pot in pairs(self._pots) do
		pot:destroy()
	end

	self._instance:Destroy()
	self.changed:DisconnectAll()
end

return Table
