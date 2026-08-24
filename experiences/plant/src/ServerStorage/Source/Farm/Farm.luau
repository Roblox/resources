--!strict

--[[
	Class associated with a farm instance that provides serialization & deserialization
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local Table = require(ServerStorage.Source.Farm.Table)
local Signal = require(ReplicatedStorage.Source.Signal)
local Wagon = require(ServerStorage.Source.Farm.Wagon)
local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local PlacementTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PlacementTag)
local PlaceableArea = require(ServerStorage.Source.Farm.PlaceableArea)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local Connections = require(ReplicatedStorage.Source.Connections)
local weldDescendantsToPrimaryPart = require(ReplicatedStorage.Source.Utility.weldDescendantsToPrimaryPart)
local moveModelByAttachment = require(ReplicatedStorage.Source.Utility.moveModelByAttachment)
local getSortedIdsInCategory = require(ReplicatedStorage.Source.Utility.Farm.getSortedIdsInCategory)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local farmPrefab: Model = getInstance(ServerStorage, "Instances", "Farm")
local validItemPlacementIds = getSortedIdsInCategory(ItemCategory.Tables)

export type FarmData = {
	tables: { [string]: Table.TableData? },
	wagon: Wagon.WagonData,
	holdingPlantId: string?,
}

local Farm = {}
Farm.__index = Farm

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Model,
		_ownerPlayer: Player,
		_wagon: Wagon.ClassType?,
		_tables: { [string]: Table.ClassType },
		_placeableAreas: { [string]: PlaceableArea.ClassType },
		_hasLoaded: boolean,
		_connections: Connections.ClassType,
		changed: Signal.ClassType,
	},
	Farm
))

function Farm.new(owner: Player): ClassType
	local self = {
		_instance = farmPrefab:Clone(),
		_ownerPlayer = owner,
		_wagon = nil,
		_tables = {},
		_placeableAreas = {},
		_hasLoaded = false,
		_connections = Connections.new(),
		changed = Signal.new(),
	}

	setmetatable(self, Farm)

	self:closeDoor()
	self._instance:SetAttribute(Attribute.OwnerId, owner.UserId)

	return self
end

function Farm.getData(self: ClassType)
	assert(self._wagon, "Wagon not loaded")

	local tablesData = Freeze.Dictionary.map(self._tables, function(tableObject: Table.ClassType, spotKey: string)
		return tableObject:getData(), spotKey
	end)

	local playerPickupHandler = PlayerObjectsContainer.getPlayerPickupHandler(self._ownerPlayer)

	local data: FarmData = {
		tables = tablesData,
		wagon = self._wagon:getData(),
		holdingPlantId = playerPickupHandler:getHeldPickupId(),
	}

	return data
end

function Farm._findSpotModel(self: ClassType, spotNumber: number): Model?
	local tableSpots: Folder = getInstance(self._instance, "TableSpots")
	local spot: any = tableSpots:FindFirstChild("Spot" .. spotNumber)
	return spot :: Model?
end

function Farm._getNumberOfSpots(self: ClassType)
	local numberOfSpots = 0

	while self:_findSpotModel(numberOfSpots + 1) do
		numberOfSpots += 1
	end

	return numberOfSpots
end

function Farm.loadData(self: ClassType, farmData: FarmData)
	assert(not self._hasLoaded, "Attempt to load farm data twice")
	weldDescendantsToPrimaryPart(self._instance)
	self:_loadWagon(farmData.wagon)

	-- Using a dictionary instead of array to allow tables to be placed in any order (spot1 = tableA, spot2 = nil, spot3 = tableB)
	for spotNumber = 1, self:_getNumberOfSpots() do
		local spotKey = self:_getKeyForSpotNumber(spotNumber)
		local tableData: Table.TableData? = farmData.tables[spotKey]

		if tableData then
			self._tables[spotKey] = self:_createTableAt(spotNumber, tableData)
		else
			self:_createPlaceableTableArea(spotNumber)
		end
	end

	self:_loadPlayerPickupHandler(farmData.holdingPlantId)
	self._hasLoaded = true
end

function Farm._getKeyForSpotNumber(self: ClassType, spotNumber)
	return "spot" .. spotNumber
end

function Farm._createPlaceableTableArea(self: ClassType, spotNumber: number)
	local spotKey = self:_getKeyForSpotNumber(spotNumber)
	local tableSpotModel = self:_findSpotModel(spotNumber)
	assert(tableSpotModel, "TableSpotModel does not exist")

	local placeableArea = PlaceableArea.new(tableSpotModel, validItemPlacementIds, PlacementTag.CanPlaceTable)

	-- This connection gets disconnected when placeableArea gets destroyed
	placeableArea.placeRequested:Connect(function(_: any, itemId: any)
		self._placeableAreas[spotKey] = nil
		placeableArea:destroy()

		self._tables[spotKey] = self:_createTableAt(spotNumber, {
			id = itemId :: string,
			pots = {},
		})
	end)
	self._placeableAreas[spotKey] = placeableArea
end

function Farm._loadWagon(self: ClassType, wagonData: Wagon.WagonData)
	local wagon = Wagon.new(wagonData)
	self._wagon = wagon

	local wagonAttachment: Attachment = getInstance(self._instance, "InsideWagonSpawn", "WagonAttachment")
	wagon:movePrimaryAttachmentTo(wagonAttachment.WorldCFrame)
	wagon:getInstance().Parent = self._instance

	local connection = wagon.changed:Connect(function()
		self.changed:Fire()
	end)
	self._connections:add(connection)
end

function Farm._loadPlayerPickupHandler(self: ClassType, holdingPlantId: string?)
	local playerPickupHandler = PlayerObjectsContainer.getPlayerPickupHandler(self._ownerPlayer)

	if holdingPlantId then
		playerPickupHandler:startHolding(holdingPlantId)
	end

	local connection = playerPickupHandler.changed:Connect(function()
		self.changed:Fire()
	end)
	self._connections:add(connection)
end

function Farm._createTableAt(self: ClassType, spotNumber: number, tableData: Table.TableData)
	local tableSpotModel = self:_findSpotModel(spotNumber)
	assert(tableSpotModel, "TableSpotModel does not exist")
	local tableObject = Table.new(tableData)

	local connection = tableObject.changed:Connect(function()
		self.changed:Fire()
	end)
	self._connections:add(connection)

	local tableAttachment: Attachment = getInstance(tableSpotModel.PrimaryPart :: BasePart, "TableAttachment")
	local contents: Folder = getInstance(tableSpotModel, "Contents")

	tableObject:attachTo(tableAttachment)
	tableObject:getInstance().Parent = contents
	if self._hasLoaded then
		-- Deferred to give a chance for the caller to use the return value and update data before listeners activate
		task.defer(self.changed.Fire, self.changed)
	end

	return tableObject
end

-- The farm door is only used during FTUE to close the player in until onboarding steps are completed
function Farm.openDoor(self: ClassType)
	local door: MeshPart = getInstance(self._instance, "GreenhouseDoor")
	local hinge: HingeConstraint = getInstance(door, "HingeConstraint")

	local openAngle: number = getAttribute(door, Attribute.DoorOpenAngle)
	hinge.TargetAngle = openAngle
end

function Farm.closeDoor(self: ClassType)
	local door: MeshPart = getInstance(self._instance, "GreenhouseDoor")
	local hinge: HingeConstraint = getInstance(door, "HingeConstraint")

	local closeAngle: number = getAttribute(door, Attribute.DoorCloseAngle)
	hinge.TargetAngle = closeAngle
end

function Farm.movePrimaryAttachmentTo(self: ClassType, targetCFrame: CFrame)
	local farmAttachment: Attachment = getInstance(self._instance.PrimaryPart :: BasePart, "FarmAttachment")
	moveModelByAttachment(self._instance, farmAttachment, targetCFrame)
end

function Farm.getInstance(self: ClassType)
	return self._instance
end

function Farm.getWagon(self: ClassType)
	return self._wagon
end

function Farm.destroy(self: ClassType)
	self._connections:disconnect()

	if self._wagon then
		self._wagon:destroy()
	end

	for _, placeableArea in pairs(self._placeableAreas) do
		placeableArea:destroy()
	end

	for _, tableObject in pairs(self._tables) do
		tableObject:destroy()
	end

	self._instance:Destroy()
	self.changed:DisconnectAll()
end

return Farm
