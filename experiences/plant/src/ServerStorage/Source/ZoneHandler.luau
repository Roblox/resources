--!strict

--[[
	Tracks a model's location based on its primary part, checking if it's within a zone.
	Adds tags to the model depending on which zones it is in.

	This class assumes zones are static and that these ZoneParts exist when the class is constructed.

	Each ZonePart should also have a string attribute, Attribute.ZoneId, containing the name of the zone
	corresponding with a ZoneTag.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local ZonePartTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZonePartTag)
local ZoneIdTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZoneIdTag)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)

local CHECK_INTERVAL = 0.5

local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local setInterval = require(ReplicatedStorage.Source.Utility.setInterval)

local ZoneHandler = {}
ZoneHandler.__index = ZoneHandler

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Model,
		_overlapParams: OverlapParams?,
		_clearInterval: (() -> nil)?,
		_destroyed: boolean,
	},
	ZoneHandler
))

function ZoneHandler.new(instance: Model): ClassType
	local self = {
		_instance = instance,
		_overlapParams = nil,
		_clearInterval = nil,
		_destroyed = false,
	}

	setmetatable(self, ZoneHandler)

	task.spawn(function()
		self:_setupAsync()

		if self._destroyed then
			return
		end

		self:_watchForZoneChange()
	end)

	return self
end

function ZoneHandler._setupAsync(self: ClassType)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = CollectionService:GetTagged(ZonePartTag)
	self._overlapParams = overlapParams

	if not self._instance.PrimaryPart then
		self._instance:GetPropertyChangedSignal("PrimaryPart"):Wait()
	end
end

function ZoneHandler._updateZoneTags(self: ClassType)
	local primaryPartMaybe = self._instance.PrimaryPart
	if not primaryPartMaybe then
		return
	end

	local primaryPart = primaryPartMaybe :: BasePart

	local tagsAdded = {}
	local zoneParts = Workspace:GetPartsInPart(primaryPart, self._overlapParams)

	-- Add new zone tags
	for _, zonePart in ipairs(zoneParts) do
		local zoneName: string = getAttribute(zonePart, Attribute.ZoneId)
		local zoneTag = ZoneIdTag[zoneName]

		assert(zoneTag, string.format("Zone '%s' is missing from ZoneIdTag", zoneName))

		CollectionService:AddTag(self._instance, zoneTag)
		tagsAdded[zoneTag] = true
	end

	-- Remove old zone tags
	for _, zoneTag in pairs(ZoneIdTag) do
		if tagsAdded[zoneTag] then
			continue
		end

		CollectionService:RemoveTag(self._instance, zoneTag)
	end
end

function ZoneHandler._watchForZoneChange(self: ClassType)
	self._clearInterval = setInterval(function()
		self:_updateZoneTags()
	end, CHECK_INTERVAL)
end

function ZoneHandler.destroy(self: ClassType)
	self._destroyed = true

	if self._clearInterval then
		self._clearInterval()
	end
end

return ZoneHandler
