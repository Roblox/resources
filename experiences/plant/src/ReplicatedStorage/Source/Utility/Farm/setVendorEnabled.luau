--!strict

--[[
	Enable/disable outside vendors. Disabled vendors have no NPC, ring, or floating
	sign above them, and do not trigger UI opening when the player is near.

	Vendors must have a child named "ZonePart" which has a ZoneId attribute corresponding to a zone in UILayerIdByZoneId.
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIZoneHandler = require(ReplicatedStorage.Source.UI.UIZoneHandler)
local VisibleWhenVendorEnabledTag =
	require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.VisibleWhenVendorEnabledTag)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local ZoneIdTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZoneIdTag)
local UILayerIdByZoneId = require(ReplicatedStorage.Source.SharedConstants.UILayerIdByZoneId)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local parentsByObjectsByVendor = {} :: {
	-- [VendorModel]
	[Model]: {
		-- [object]: parent
		[Instance]: Instance,
	},
}

local function enableVendor(vendor: Model)
	for object, parent in pairs(parentsByObjectsByVendor[vendor] or {}) do
		object.Parent = parent
	end
	parentsByObjectsByVendor[vendor] = nil

	-- This assumes only exactly ZonePart per vendor
	local zonePart: BasePart = getInstance(vendor, "ZonePart")
	local zoneIdAttribute: string = getAttribute(zonePart, Attribute.ZoneId)
	local zoneId = ZoneIdTag[zoneIdAttribute]
	assert(
		zoneId,
		string.format(
			"Vendor ZonePart %s has an invalid zoneId attribute '%s', which is not in the ZoneIdTag list.",
			zonePart:GetFullName(),
			zoneIdAttribute
		)
	)
	local uiLayerId: UILayerId.EnumType? = UILayerIdByZoneId[zoneId]
	if uiLayerId then
		UIZoneHandler.connectUiToZone(uiLayerId, zoneId)
	end
end

local function disableVendor(vendor: Model)
	parentsByObjectsByVendor[vendor] = parentsByObjectsByVendor[vendor] or {}
	for _, object in ipairs(vendor:GetDescendants()) do
		if CollectionService:HasTag(object, VisibleWhenVendorEnabledTag) then
			parentsByObjectsByVendor[vendor][object] = object.Parent :: Instance
			object.Parent = nil
		end

		if object.Name == "ZonePart" then
			local zoneIdAttribute: string = getAttribute(object, Attribute.ZoneId)
			local zoneId = ZoneIdTag[zoneIdAttribute]
			assert(
				zoneId,
				string.format(
					"Vendor ZonePart %s has an invalid zoneId attribute '%s', which is not in the ZoneIdTag list.",
					object:GetFullName(),
					zoneIdAttribute
				)
			)
			local uiLayerId: UILayerId.EnumType? = UILayerIdByZoneId[zoneId]
			if uiLayerId then
				UIZoneHandler.disconnectUiFromZone(uiLayerId, zoneId)
			end
		end
	end
end

local function setVendorEnabled(vendor: Model, isEnabled: boolean)
	if isEnabled then
		enableVendor(vendor)
	else
		disableVendor(vendor)
	end
end

return setVendorEnabled
