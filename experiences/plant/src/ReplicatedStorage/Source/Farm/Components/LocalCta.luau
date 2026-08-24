--!strict

--[[
	Creates the given CTA object only if the instance is owned
	by the local player, otherwise this does nothing
--]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CallToAction = require(ReplicatedStorage.Source.CallToAction)
local CtaDataType = require(ReplicatedStorage.Source.Farm.CtaDataType)
local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)
local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local Connections = require(ReplicatedStorage.Source.Connections)
local TagEnumType = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.TagEnumType)
local Signal = require(ReplicatedStorage.Source.Signal)
local connectAll = require(ReplicatedStorage.Source.Utility.connectAll)
local getFarmOwnerIdFromInstance = require(ReplicatedStorage.Source.Utility.Farm.getFarmOwnerIdFromInstance)

local localPlayer = Players.LocalPlayer :: Player

local LocalCta = {}
LocalCta.__index = LocalCta

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Instance,
		_cta: CallToAction.ClassType?,
		_ctaData: CtaDataType.CtaData,
		_characterLoadedWrapper: CharacterLoadedWrapper.ClassType,
		_connections: Connections.ClassType,
	},
	LocalCta
))

function LocalCta.new(instance: Instance, ctaData: CtaDataType.CtaData): ClassType
	local ownerId = getFarmOwnerIdFromInstance(instance)
	assert(ownerId, string.format("Unable to retrieve ownerId for instance %s", instance:GetFullName()))

	local self = {
		_instance = instance,
		_cta = nil,
		_ctaData = ctaData,
		_characterLoadedWrapper = CharacterLoadedWrapper.new(localPlayer),
		_connections = Connections.new(),
	}

	setmetatable(self, LocalCta)

	-- Only add CTA to locally owned instances
	-- TODO: Debug ownerId not existing while farm is loading
	if ownerId == localPlayer.UserId then
		self:_listen()
	end

	return self
end

function LocalCta._createCta(self: ClassType)
	if self._cta then
		return
	end

	self._cta = CallToAction.new(self._instance, self._ctaData)
end

function LocalCta._destroyCta(self: ClassType)
	if not self._cta then
		return
	end
	local cta = self._cta :: CallToAction.ClassType
	cta:destroy()

	self._cta = nil
end

function LocalCta._updateCtaVisibility(self: ClassType)
	if self:_shouldEnable() then
		self:_createCta()
	else
		self:_destroyCta()
	end
end

function LocalCta._shouldEnable(self: ClassType)
	-- Disable CTAs while dead
	if not self._characterLoadedWrapper:isLoaded() then
		return false
	end

	if self._ctaData.shouldEnable then
		if not self._ctaData.shouldEnable(self._instance) then
			return false
		end
	end

	return true
end

function LocalCta._listen(self: ClassType)
	if not self._ctaData.listenToTags and not self._ctaData.listenToPlayerDataValues then
		self:_createCta()
		return
	end

	-- The CTA is always shown unless conditions are specified by either listenToTags and/or listenToPlayerDataValues.
	-- If these are non-nil, the shouldEnable function is called whenever the underlying tags or player data keys are changed.
	-- For this reason, shouldEnable must be present when either listenToTags or listenToPlayerDataValues is specified.
	assert(
		self._ctaData.shouldEnable,
		"shouldEnable must be specified when listenToTags or listenToPlayerDataValues is not nil"
	)

	if self._ctaData.listenToTags then
		for _, tag: TagEnumType.EnumType in self._ctaData.listenToTags do
			self:_listenToSignals({
				CollectionService:GetInstanceAddedSignal(tag),
				CollectionService:GetInstanceRemovedSignal(tag),
			})
		end
	end

	if self._ctaData.listenToPlayerDataValues then
		for _, tag in ipairs(self._ctaData.listenToPlayerDataValues) do
			self:_listenToPlayerDataValue(tag)
		end
	end

	if self._ctaData.listenToSignals then
		self:_listenToSignals(self._ctaData.listenToSignals)
	end

	task.spawn(function()
		if not self._characterLoadedWrapper:isLoaded() then
			self._characterLoadedWrapper.loaded:Wait()
		end

		self:_updateCtaVisibility()

		local newConnections = connectAll({
			self._characterLoadedWrapper.loaded,
			self._characterLoadedWrapper.died,
		}, function()
			self:_updateCtaVisibility()
		end)

		self._connections:add(table.unpack(newConnections))
	end)
end

function LocalCta._listenToSignals(self: ClassType, signals: { RBXScriptSignal | Signal.ClassType })
	local newConnections = connectAll(signals, function()
		self:_updateCtaVisibility()
	end)

	self._connections:add(table.unpack(newConnections))
end

function LocalCta._listenToPlayerDataValue(self: ClassType, valueName: string)
	local dataUpdatedConnection = PlayerDataClient.updated:Connect(function(changedValueName: any)
		if changedValueName :: string == valueName then
			self:_updateCtaVisibility()
		end
	end)

	self._connections:add(dataUpdatedConnection)
end

function LocalCta.destroy(self: ClassType)
	self._connections:disconnect()

	self:_destroyCta()
end

return LocalCta
