--!strict

--[[
	Handles server side of picking up items, such as welding the pickup to the character
	Provides public methods to pick up, let go, and and get details of the object being held
--]]

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Source.Signal)
local PickupPrefabsById = require(ServerStorage.Source.PickupPrefabsById)
local rigidlyAttach = require(ReplicatedStorage.Source.Utility.rigidlyAttach)
local getCharacterAttachment = require(ReplicatedStorage.Source.Utility.getCharacterAttachment)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local PlayerPickupHandler = {}
PlayerPickupHandler.__index = PlayerPickupHandler

export type ClassType = typeof(setmetatable(
	{} :: {
		_player: Player,
		_heldPickupId: string?,
		_heldModel: Model?,
		_characterLoadedWrapper: CharacterLoadedWrapper.ClassType,
		_characterLoadedConnection: Signal.SignalConnection?,
		changed: Signal.ClassType,
	},
	PlayerPickupHandler
))

function PlayerPickupHandler.new(player: Player, characterLoadedWrapper: CharacterLoadedWrapper.ClassType): ClassType
	local self = {
		_player = player,
		_heldPickupId = nil,
		_heldModel = nil,
		_characterLoadedWrapper = characterLoadedWrapper,
		_characterLoadedConnection = nil,
		changed = Signal.new(),
	}

	setmetatable(self, PlayerPickupHandler)

	return self
end

function PlayerPickupHandler.getHeldPickupId(self: ClassType)
	return self._heldPickupId
end

function PlayerPickupHandler.getHeldInstance(self: ClassType)
	return self._heldModel
end

function PlayerPickupHandler.isHolding(self: ClassType)
	return self._heldPickupId and true or false
end

function PlayerPickupHandler.startHolding(self: ClassType, pickupId: string)
	if self:isHolding() then
		return
	end

	self._heldPickupId = pickupId
	if self._characterLoadedWrapper:isLoaded() then
		self:_attachPickupToCharacter(pickupId)
	end

	-- Allows the player to keep the item they were holding when they respawn
	self._characterLoadedConnection = self._characterLoadedWrapper.loaded:Connect(function()
		self:_attachPickupToCharacter(pickupId)
	end)

	self.changed:Fire(pickupId)
end

function PlayerPickupHandler.stopHolding(self: ClassType)
	if not self:isHolding() then
		return
	end

	local characterMaybe = self._player.Character
	if characterMaybe then
		local character = characterMaybe :: Model
		CollectionService:RemoveTag(character, CharacterTag.Holding)
		character:SetAttribute(Attribute.Holding, nil)
	end

	if self._characterLoadedConnection then
		self._characterLoadedConnection:Disconnect()
		self._characterLoadedConnection = nil
	end

	local heldModel = self._heldModel :: Model
	heldModel:Destroy()
	self._heldModel = nil

	self._heldPickupId = nil
	self.changed:Fire(nil)
end

function PlayerPickupHandler._attachPickupToCharacter(self: ClassType, pickupId: string)
	local character = self._player.Character
	assert(character, "Character does not exist")

	local instance = PickupPrefabsById[pickupId]:Clone()
	assert(instance.PrimaryPart, "Instance has no PrimaryPart")

	instance.PrimaryPart.Anchored = false

	-- TODO: Figure out animation when picking up
	local pickupAttachmentName: string = getAttribute(instance, Attribute.PickupAttachmentName)
	local pickupAttachment: Attachment = getInstance(instance.PrimaryPart, pickupAttachmentName)
	assert(pickupAttachment, string.format("Missing pickup attachment in '%s'", instance.PrimaryPart:GetFullName()))

	local characterAttachment = getCharacterAttachment(character, pickupAttachment.Name)
	rigidlyAttach(pickupAttachment, characterAttachment)

	instance.Parent = character
	self._heldModel = instance

	instance.PrimaryPart:SetNetworkOwner(self._player)

	character:SetAttribute(Attribute.Holding, pickupId)
	CollectionService:AddTag(character, CharacterTag.Holding)
end

function PlayerPickupHandler.destroy(self: ClassType)
	self.changed:DisconnectAll()
	self:stopHolding()
end

return PlayerPickupHandler
