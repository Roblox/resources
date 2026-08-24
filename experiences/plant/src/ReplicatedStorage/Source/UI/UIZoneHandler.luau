--!strict

--[[
	Provides a client API to connect and disconnect UILayers from Zones.
	A connected UILayer opens on the local player's screen when the player enters the connected zone.
--]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHandler = require(script.Parent.UIHandler)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local ZoneIdTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZoneIdTag)

local localPlayer = Players.LocalPlayer :: Player

type ConnectionsByName = {
	-- [ConnectionName] = Connection
	[string]: RBXScriptConnection,
}

type ConnectionsByLayerId = {
	-- [UILayerId]
	[string]: ConnectionsByName,
}
type ConnectionsByZoneId = {
	-- [ZoneId]
	[string]: ConnectionsByLayerId,
}

local UIZoneHandler = {}
UIZoneHandler._uiConnectionsByZoneId = {} :: ConnectionsByZoneId

function UIZoneHandler.connectUiToZone(uiLayerId: UILayerId.EnumType, zoneId: ZoneIdTag.EnumType)
	local characterMaybe = localPlayer.Character

	if characterMaybe and CollectionService:HasTag(characterMaybe, zoneId) then
		UIHandler.show(uiLayerId)
	else
		UIHandler.hide(uiLayerId)
	end

	local connectionsByLayerId: ConnectionsByLayerId = UIZoneHandler._uiConnectionsByZoneId[zoneId] or {}
	local connectionsByName: ConnectionsByName = connectionsByLayerId[uiLayerId] or {}

	if not connectionsByName.instanceAddedSignal then
		connectionsByName.instanceAddedSignal = CollectionService:GetInstanceAddedSignal(zoneId)
			:Connect(function(instance: Instance)
				if instance ~= localPlayer.Character then
					return
				end

				UIHandler.show(uiLayerId)
			end)
	end

	if not connectionsByName.instanceRemovedSignal then
		connectionsByName.instanceRemovedSignal = CollectionService:GetInstanceRemovedSignal(zoneId)
			:Connect(function(instance: Instance)
				if instance ~= localPlayer.Character then
					return
				end

				UIHandler.hide(uiLayerId)
			end)
	end

	connectionsByLayerId[uiLayerId] = connectionsByName
	UIZoneHandler._uiConnectionsByZoneId[zoneId] = connectionsByLayerId
end

function UIZoneHandler.disconnectUiFromZone(uiLayerId: UILayerId.EnumType, zoneId: ZoneIdTag.EnumType)
	local connectionsByLayerId = UIZoneHandler._uiConnectionsByZoneId[zoneId]
	if not connectionsByLayerId then
		return
	end

	local connectionsByName = connectionsByLayerId[uiLayerId]
	if not connectionsByName then
		return
	end

	for _, connection in pairs(connectionsByName) do
		connection:Disconnect()
	end

	connectionsByLayerId[uiLayerId] = nil
end

return UIZoneHandler
