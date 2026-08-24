--!strict

--[[
	Server-side handling of wagon contents, including responding to
	placing requests, tracking contents, and some public API members
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local Signal = require(ReplicatedStorage.Source.Signal)
local Network = require(ReplicatedStorage.Source.Network)
local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local WagonTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.WagonTag)
local Connections = require(ReplicatedStorage.Source.Connections)
local RemoteEvents = Network.RemoteEvents
local getFarmOwnerIdFromInstance = require(ReplicatedStorage.Source.Utility.Farm.getFarmOwnerIdFromInstance)
local createHarvestedPlantModel = require(ServerStorage.Source.Farm.createHarvestedPlantModel)
local weldDescendantsToPrimaryPart = require(ReplicatedStorage.Source.Utility.weldDescendantsToPrimaryPart)
local weldParts = require(ReplicatedStorage.Source.Utility.weldParts)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local t = Network.t

local ContentsManager = {}
ContentsManager.__index = ContentsManager

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Model,
		_connections: Connections.ClassType,
		changed: Signal.ClassType,
	},
	ContentsManager
))

function ContentsManager.new(wagonModel: Model, contents: { string }): ClassType
	local self = {
		_instance = wagonModel,
		_connections = Connections.new(),
		changed = Signal.new(),
	}

	setmetatable(self, ContentsManager)

	self:_loadData(contents)
	self:_listenForPlacement()

	return self
end

function ContentsManager.getPlantIds(self: ClassType)
	local contentsArray: { string } = {}

	local plantSpots: Model = getInstance(self._instance, "PlantSpots")
	for _, spotModel in ipairs(plantSpots:GetChildren()) do
		local contentsFolder: Folder = getInstance(spotModel, "Contents")
		local contents = contentsFolder:GetChildren()

		assert(#contents <= 1, "Wagon plant contents folder must only have up to 1 child")
		if #contents == 1 then
			local plantId = contents[1].Name
			table.insert(contentsArray, plantId)
		end
	end

	return contentsArray
end

function ContentsManager.clearContents(self: ClassType)
	if self:isEmpty() then
		return
	end

	local plantSpots: Model = getInstance(self._instance, "PlantSpots")
	for _, spotModel in ipairs(plantSpots:GetChildren()) do
		getInstance(spotModel, "Contents"):ClearAllChildren()
	end

	CollectionService:RemoveTag(self._instance, WagonTag.WagonFull)
	CollectionService:AddTag(self._instance, WagonTag.WagonEmpty)

	self.changed:Fire()
end

function ContentsManager.getNumSpots(self: ClassType)
	local plantSpots: Model = getInstance(self._instance, "PlantSpots")
	return #plantSpots:GetChildren()
end

function ContentsManager.isFull(self: ClassType)
	return self:getNumSpots() == #self:getPlantIds()
end

function ContentsManager.isEmpty(self: ClassType)
	return #self:getPlantIds() == 0
end

function ContentsManager._loadData(self: ClassType, contents: { string })
	for plantNumber, plantName in ipairs(contents) do
		self:_placePlant(plantName)
	end

	if self:isEmpty() then
		CollectionService:AddTag(self._instance, WagonTag.WagonEmpty)
	end
end

function ContentsManager._getEmptySpot(self: ClassType)
	local contents = self:getPlantIds()
	local nextEmptyIndex = #contents + 1
	local emptySpot: Model?

	local plantSpots: Model = getInstance(self._instance, "PlantSpots")
	if nextEmptyIndex <= self:getNumSpots() then
		local spotName = "Spot" .. nextEmptyIndex
		emptySpot = getInstance(plantSpots, spotName)
	end

	return emptySpot
end

function ContentsManager._canPlace(self: ClassType, player: Player, plantName: string)
	-- plantName would only be missing if the player tries to place the plant without holding one, e.g. exploiter firing remotes
	if not plantName then
		return false
	end

	if player.UserId ~= getFarmOwnerIdFromInstance(self._instance) then
		return false
	end

	if self:isFull() then
		return false
	end

	return true
end

function ContentsManager._placePlant(self: ClassType, plantName: string)
	local emptySpot = self:_getEmptySpot()
	assert(emptySpot, "No empty spot is present")

	local placedPlant = createHarvestedPlantModel(plantName)
	weldDescendantsToPrimaryPart(placedPlant)
	placedPlant:PivotTo(emptySpot:GetPivot())

	local placedPlantPrimaryPart = placedPlant.PrimaryPart :: BasePart
	weldParts(placedPlantPrimaryPart, emptySpot.PrimaryPart :: BasePart)
	placedPlantPrimaryPart.Anchored = false
	placedPlant.Parent = getInstance(emptySpot, "Contents")

	self.changed:Fire()

	if self:isFull() then
		CollectionService:AddTag(self._instance, WagonTag.WagonFull)
	end

	CollectionService:RemoveTag(self._instance, WagonTag.WagonEmpty)
end

function ContentsManager._listenForPlacement(self: ClassType)
	local connection = Network.connectEvent(RemoteEvents.PlantPlaced, function(player: Player)
		local playerPickupHandler = PlayerObjectsContainer.getPlayerPickupHandler(player)
		local plantNameMaybe = playerPickupHandler:getHeldPickupId()

		if not plantNameMaybe then
			return
		end
		local plantName = plantNameMaybe :: string

		if not self:_canPlace(player, plantName) then
			return
		end

		self:_placePlant(plantName)
		playerPickupHandler:stopHolding()
	end, t.tuple(t.instanceOf("Player")))

	self._connections:add(connection)
end

function ContentsManager.destroy(self: ClassType)
	self._connections:disconnect()

	self.changed:DisconnectAll()
end

return ContentsManager
