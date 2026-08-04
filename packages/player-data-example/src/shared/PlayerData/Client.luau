--!strict

--[[
	Client-side component of the PlayerData system, which handles key/value based persistent player data.

	For more information and wider context, please see ServerStorage/Source/PlayerData/Readme.lua
--]]

local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)
local PlayerDataErrorType = require(script.Parent.Modules.PlayerDataErrorType)
local TableUtils = require(script.Parent.Modules.TableUtils)

local playerDataLoaded = script.Parent.Remotes.PlayerDataLoaded
local playerDataUpdated = script.Parent.Remotes.PlayerDataUpdated
local playerDataSaved = script.Parent.Remotes.PlayerDataSaved

type PlayerData = { [string]: any }

local PlayerDataClient = {}
PlayerDataClient._data = {} :: PlayerData
PlayerDataClient._loadErrorType = nil :: PlayerDataErrorType.EnumType?
PlayerDataClient._saveErrorType = nil :: PlayerDataErrorType.EnumType?
PlayerDataClient._hasLoaded = false
PlayerDataClient.loaded = Signal.new()
PlayerDataClient.updated = Signal.new()
PlayerDataClient.saved = Signal.new()

function PlayerDataClient.start()
	assert(RunService:IsClient(), "PlayerDataClient can only be started on the client")

	PlayerDataClient._listenForEvents()
end

-- Returns true if the player's data failed to load (and thus is using fallback default data)
function PlayerDataClient.hasLoadingErrored()
	local hasErrored = if PlayerDataClient._loadErrorType then true else false

	return hasErrored
end

-- Returns true if the last attempt to save the player's data failed
function PlayerDataClient.hasSavingErrored()
	local hasErrored = if PlayerDataClient._saveErrorType then true else false

	return hasErrored
end

-- Returns the error type encountered while loading
-- Will return nil if PlayerDataClient.hasLoadingErrored returns false
function PlayerDataClient.getLoadError(): PlayerDataErrorType.EnumType?
	return PlayerDataClient._loadErrorType :: PlayerDataErrorType.EnumType?
end

-- Returns the last error type encountered while saving
-- Will return nil if PlayerDataClient.hasSavingErrored returns false
function PlayerDataClient.getSaveError(): PlayerDataErrorType.EnumType?
	return PlayerDataClient._saveErrorType :: PlayerDataErrorType.EnumType?
end

-- Returns true if the player's data has finished loading
-- The PlayerDataClient.loaded event can be used to wait for this to occur
function PlayerDataClient.hasLoaded()
	return PlayerDataClient._hasLoaded
end

-- Returns the value for the given value name
function PlayerDataClient.get(valueName: string)
	assert(PlayerDataClient._hasLoaded, "The player's data is still loading")

	local value = PlayerDataClient._data[valueName]
	-- Deep copy tables before returning them so the actual value can not be modified from outside of this module
	if typeof(value) == "table" then
		value = TableUtils.deepCopy(value)
	end

	return value
end

function PlayerDataClient._onDataLoaded(data: PlayerData, success: boolean, errorType: PlayerDataErrorType.EnumType?)
	PlayerDataClient._data = data
	PlayerDataClient._loadErrorType = errorType
	PlayerDataClient._hasLoaded = true

	PlayerDataClient.loaded:Fire(success, PlayerDataClient._loadErrorType)
end

function PlayerDataClient._onDataUpdated(valueName: string, value: any)
	PlayerDataClient._data[valueName] = value

	-- Deep copy tables before firing updated so the actual value can not be modified from outside of this module
	if typeof(value) == "table" then
		value = TableUtils.deepCopy(value)
	end

	PlayerDataClient.updated:Fire(valueName, value)
end

function PlayerDataClient._onDataSaved(success: boolean, errorType: PlayerDataErrorType.EnumType?)
	PlayerDataClient._saveErrorType = errorType
	PlayerDataClient.saved:Fire(success, errorType)
end

function PlayerDataClient._listenForEvents()
	playerDataLoaded.OnClientEvent:Connect(
		function(data: PlayerData, success: boolean, errorType: PlayerDataErrorType.EnumType?)
			PlayerDataClient._onDataLoaded(data, success, errorType)
		end
	)

	playerDataUpdated.OnClientEvent:Connect(function(valueName: string, value: any)
		PlayerDataClient._onDataUpdated(valueName, value)
	end)

	playerDataSaved.OnClientEvent:Connect(function(success: boolean, errorType: PlayerDataErrorType.EnumType?)
		PlayerDataClient._onDataSaved(success, errorType)
	end)
end

return PlayerDataClient
