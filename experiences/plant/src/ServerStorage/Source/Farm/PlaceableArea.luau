--!strict

--[[
	Handles creating visuals indicating an object
	can be placed inside the given parent model.
--]]

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local Signal = require(ReplicatedStorage.Source.Signal)
local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local Connections = require(ReplicatedStorage.Source.Connections)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local PlacementTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PlacementTag)
local rigidlyAttach = require(ReplicatedStorage.Source.Utility.rigidlyAttach)
local getFarmOwnerFromInstance = require(ReplicatedStorage.Source.Utility.Farm.getFarmOwnerIdFromInstance)
local getCategoryForItemId = require(ReplicatedStorage.Source.Utility.Farm.getCategoryForItemId)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local t = Network.t
local placeableAreaPrefab: Model = getInstance(ReplicatedStorage, "Instances", "PlaceableAreaPrefab")

local PlaceableArea = {}
PlaceableArea.__index = PlaceableArea

export type ClassType = typeof(setmetatable(
	{} :: {
		_parent: Model,
		_instance: Model,
		_validItemIds: { string },
		_placementTag: PlacementTag.EnumType,
		_connections: Connections.ClassType,
		placeRequested: Signal.ClassType,
	},
	PlaceableArea
))

function PlaceableArea.new(parent: Model, validItemIds: { string }, placementTag: PlacementTag.EnumType): ClassType
	local self = {
		_parent = parent,
		_instance = placeableAreaPrefab:Clone(),
		_validItemIds = validItemIds,
		_placementTag = placementTag,
		_connections = Connections.new(),
		placeRequested = Signal.new(),
	}

	setmetatable(self, PlaceableArea)

	self:_setup()

	return self
end

function PlaceableArea._setup(self: ClassType)
	self:_setupInstance()
	self:_listenForPlaceRequest()

	CollectionService:AddTag(self._parent, self._placementTag)
end

function PlaceableArea._setupInstance(self: ClassType)
	local parentSize = self._parent:GetExtentsSize()
	local instancePrimaryPart = self._instance.PrimaryPart :: BasePart
	local instanceIndicatorAttachment: Attachment = getInstance(instancePrimaryPart, "IndicatorAttachment")
	local parentPrimaryPart = self._parent.PrimaryPart :: BasePart
	local parentIndicatorAttachment: Attachment = getInstance(parentPrimaryPart, "IndicatorAttachment")

	instancePrimaryPart.Size = Vector3.new(instancePrimaryPart.Size.X, parentSize.Y, parentSize.Z)
	rigidlyAttach(parentIndicatorAttachment, instanceIndicatorAttachment)
	self._instance.Parent = self._parent
end

function PlaceableArea._listenForPlaceRequest(self: ClassType)
	local requestConnection = Network.connectEvent(
		Network.RemoteEvents.RequestPlaceObject,
		function(player: Player, placeableArea: Model, itemId: string)
			if not self:_canPlace(player, placeableArea, itemId) then
				return
			end

			self:_onPlaceRequested(player, itemId)
		end,
		t.tuple(t.instanceOf("Player"), t.instanceOf("Model"), t.string)
	)

	self._connections:add(requestConnection)
end

function PlaceableArea._canPlace(self: ClassType, player: Player, placeableArea: Model, itemId: string)
	-- Ignore placement requests for other areas
	if placeableArea ~= self._parent then
		return false
	end

	-- Only allow requests to place whitelisted items
	if not table.find(self._validItemIds, itemId) then
		return false
	end

	-- Reject requests from players who don't own this farm
	if getFarmOwnerFromInstance(self._parent) ~= player.UserId then
		return false
	end

	-- Reject request if the player doesn't have the item in their inventory
	local itemCategory = getCategoryForItemId(itemId)
	local inventory = PlayerDataServer.getValue(player, PlayerDataKey.Inventory)
	local itemCountById = inventory[itemCategory]
	local itemCount = itemCountById and itemCountById[itemId] or 0
	if itemCount <= 0 then
		return false
	end

	return true
end

function PlaceableArea._onPlaceRequested(self: ClassType, player: Player, itemId: string)
	local itemCategory = getCategoryForItemId(itemId)

	-- Subtract one from inventory item count
	PlayerDataServer.updateValue(player, PlayerDataKey.Inventory, function(
		inventory: {
			[string]: { -- [category]: countByItemId
				[string]: number, -- [itemId]: count
			},
		}
	)
		local itemCountById = inventory[itemCategory]
		itemCountById[itemId] -= 1

		return inventory
	end)

	self.placeRequested:Fire(player, itemId)
end

function PlaceableArea.destroy(self: ClassType)
	CollectionService:RemoveTag(self._parent, self._placementTag)

	self._instance:Destroy()
	self.placeRequested:DisconnectAll()

	self._connections:disconnect()
end

return PlaceableArea
