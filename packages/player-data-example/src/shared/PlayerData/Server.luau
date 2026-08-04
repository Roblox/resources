--!strict

--[[
	Server-side component of the PlayerData system, which handles key/value based persistent player data.

	For more information and wider context, please see PlayerData/Readme.lua
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)
local noYield = require(script.Parent.noYield)
local SessionLockedDataStoreWrapper = require(script.Parent.Modules.SessionLockedDataStoreWrapper)
local setInterval = require(script.Parent.Modules.setInterval)
local safePlayerAdded = require(script.Parent.Modules.safePlayerAdded)
local getMaxRequestTime = require(script.Parent.Modules.getMaxRequestTime)
local PlayerDataErrorType = require(script.Parent.Modules.PlayerDataErrorType)
local TableUtils = require(script.Parent.Modules.TableUtils)

local playerDataLoaded = script.Parent.Remotes.PlayerDataLoaded
local playerDataUpdated = script.Parent.Remotes.PlayerDataUpdated
local playerDataSaved = script.Parent.Remotes.PlayerDataSaved

local ALLOW_STUDIO_ACCESS = false
local AUTO_SAVE_INTERVAL = 180
local DATA_STORE_REQUEST_ATTEMPTS = 3
local DATA_STORE_REQUEST_COOLDOWN_CONSTANT = 5
local DATA_STORE_REQUEST_COOLDOWN_EXPONENT = 5
local DEFAULT_DATA_STORE_NAME = "PlayerData"

export type PlayerData = { [string]: any }

-- We only want to load from the DataStore in a live server, or when ALLOW_STUDIO_ACCESS is true in a published studio session
-- The code below will show a warning in the console when DataStores are disabled
local dataStoresEnabled = true
if RunService:IsStudio() then
	-- If the PlaceId is zero, the game is not published
	if game.PlaceId == 0 or not ALLOW_STUDIO_ACCESS then
		warn("DataStores are disabled as this place is unpublished, or ALLOW_STUDIO_ACCESS is false.")
		dataStoresEnabled = false
	end
end

-- It is wasteful to configure the maximum retry time to exceed the interval between saves so we will warn if we predict this will the the case
local maxRequestTime = getMaxRequestTime(
	DATA_STORE_REQUEST_ATTEMPTS,
	DATA_STORE_REQUEST_COOLDOWN_CONSTANT,
	DATA_STORE_REQUEST_COOLDOWN_EXPONENT
)
if maxRequestTime > AUTO_SAVE_INTERVAL then
	warn(
		string.format(
			"The AUTO_SAVE_INTERVAL (%d) set in PlayerData Server is insufficient to accommodate the maximum request time with retries (%.2f)",
			AUTO_SAVE_INTERVAL,
			maxRequestTime
		)
	)
end

local PlayerDataServer = {}
PlayerDataServer.playerDataUpdated = Signal.new()
PlayerDataServer._playerDataLoadErrors = {} :: { [Player]: string }
PlayerDataServer._threadsPendingPlayerDataLoad = {} :: { [Player]: { thread } }
PlayerDataServer._playerData = {} :: { [Player]: PlayerData }
PlayerDataServer._playerDataSynced = {} :: { [Player]: PlayerData }
PlayerDataServer._playerDataMetadata = {} :: { [Player]: { [string]: any } }
PlayerDataServer._defaultData = {} :: PlayerData
PlayerDataServer._privateValueNames = {} :: { [string]: boolean }
-- Even though the SessionLockedDataStoreWrapper will be overwritten when PlayerDataServer.start is
-- called, we will declare it here for typechecking purposes
PlayerDataServer._sessionLockedWrapper = SessionLockedDataStoreWrapper.new(DEFAULT_DATA_STORE_NAME)
PlayerDataServer._started = false

function PlayerDataServer.start(defaultValue: PlayerData, dataStoreName: string, privateValueNames: { string }?)
	assert(not PlayerDataServer._started, "PlayerDataServer has already been started")

	dataStoreName = dataStoreName or DEFAULT_DATA_STORE_NAME

	PlayerDataServer._started = true
	PlayerDataServer._defaultData = defaultValue
	PlayerDataServer._sessionLockedWrapper = SessionLockedDataStoreWrapper.new(
		dataStoreName,
		DATA_STORE_REQUEST_ATTEMPTS,
		DATA_STORE_REQUEST_COOLDOWN_CONSTANT,
		DATA_STORE_REQUEST_COOLDOWN_EXPONENT
	)

	-- Values defined in privateValueNames will not replicate to the client.
	-- This is useful for sensitive information such as purchase history.
	-- This is passed in when the service is started to prevent these from being declared too late.
	PlayerDataServer._privateValueNames = TableUtils.invertValuesToKeys(privateValueNames or {})

	PlayerDataServer._listenForPlayers()
	PlayerDataServer._bindSavingToGameClose()
	PlayerDataServer._startAutoSaveLoop()
end

-- Returns true if the server has finished loading the player's data. This should be called before reading or writing
-- to a player's data. If this returns false, waitForDataLoadAsync can be used to yield until the data has loaded
function PlayerDataServer.hasLoaded(player: Player)
	local hasData = PlayerDataServer._playerData[player] and true or false

	return hasData
end

-- Returns true if the server is currently loading the player's data
function PlayerDataServer.isLoading(player: Player)
	local threadsPendingLoad = PlayerDataServer._threadsPendingPlayerDataLoad[player]

	if threadsPendingLoad then
		return true
	end

	return false
end

-- Returns true if PlayerDataServer was unable to load the player's data (typically due to a DataStoreService or session lock error)
function PlayerDataServer.hasErrored(player: Player)
	return PlayerDataServer._playerDataLoadErrors[player] and true or false
end

function PlayerDataServer.setValueAsPrivate(valueName: string, isPrivate: boolean)
	PlayerDataServer._privateValueNames[valueName] = isPrivate
end

-- Yields until the Player's data has loaded
-- If the player leaves before their data has loaded, the thread will be discarded
function PlayerDataServer.waitForDataLoadAsync(player: Player)
	PlayerDataServer._threadsPendingPlayerDataLoad[player] = PlayerDataServer._threadsPendingPlayerDataLoad[player]
		or {}

	-- We'll store the thread and resume it in _resumeThreadsPendingLoad when the data loads
	table.insert(PlayerDataServer._threadsPendingPlayerDataLoad[player], coroutine.running())

	coroutine.yield()
end

-- Returns the value of the given valueName in the given player's data
function PlayerDataServer.getValue(player: Player, valueName: string, syncedValueOnly: boolean?): any
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	local value
	-- If syncedValue only is passed, the value last loaded or saved to a DataStore successfully will be returned
	-- rather than the latest value loaded in memory. One use case of this is verifying if a purchase has been
	-- recorded _and_ saved to a DataStore in ProcessReceipt implementations
	if syncedValueOnly then
		value = PlayerDataServer._playerDataSynced[player][valueName]
	else
		value = PlayerDataServer._playerData[player][valueName]
	end

	-- Deep copy tables before returning them so the actual value can not be modified from outside of this module
	if typeof(value) == "table" then
		value = TableUtils.deepCopy(value)
	end

	return value
end

-- Updates the value of the given valueName in the given player's data for the given value
function PlayerDataServer.setValue(player: Player, valueName: string, value: any)
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	-- Deep copy tables before saving them so the actual value can not be modified from outside of this module
	if typeof(value) == "table" then
		value = TableUtils.deepCopy(value)
	end

	PlayerDataServer._playerData[player][valueName] = value

	-- We only want to fire an update to the client if this valueName has not been marked as private
	-- with PlayerDataServer.setValueAsPrivate
	if not PlayerDataServer._privateValueNames[valueName] then
		playerDataUpdated:FireClient(player, valueName, value)
	end

	PlayerDataServer.playerDataUpdated:Fire(player, valueName, value)
end

-- Transforms the value of the given valueName for the given player with a callback, similar to
-- DataStore:UpdateAsync
function PlayerDataServer.updateValue(player: Player, valueName: string, transformFunction: (any) -> any)
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	local oldValue = PlayerDataServer.getValue(player, valueName)

	-- This is not an async function, so we need to prohibit yielding here
	local newValue = noYield(transformFunction, oldValue)

	-- For consistency with DataStore:UpdateAsync, we will treat a nil return as an update abort
	if newValue then
		PlayerDataServer.setValue(player, valueName, newValue)
	end
end

-- Removes the given valueName from the given player's data
function PlayerDataServer.removeValue(player: Player, valueName: string)
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	local oldValue = PlayerDataServer.getValue(player, valueName)
	PlayerDataServer.setValue(player, valueName, nil)

	return oldValue
end

-- Sets the metadata for the given player that will be applied to the DataStore key associated with this player's data
function PlayerDataServer.setMetaData(player: Player, metadata: { [string]: any })
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	PlayerDataServer._playerDataMetadata[player] = TableUtils.deepCopy(metadata)
end

function PlayerDataServer._listenForPlayers()
	safePlayerAdded(function(newPlayer: Player)
		PlayerDataServer._onPlayerAddedAsync(newPlayer)
	end)
end

function PlayerDataServer._onPlayerAddedAsync(player: Player)
	local hasErrored = false
	local errorType = PlayerDataErrorType.DataStoreError

	if dataStoresEnabled then
		local key = PlayerDataServer._getKey(player)

		-- We need to pass the player's userId into the SessionLockedDataStoreWrapper so it can correctly
		-- tag it for compliance reasons when it writes the session lock metadata
		local success, result = PlayerDataServer._sessionLockedWrapper:getAsync(key, nil, { player.UserId })

		if success then
			PlayerDataServer._playerData[player] = (
				result or TableUtils.deepCopy(PlayerDataServer._defaultData)
			) :: PlayerData
			PlayerDataServer._playerDataSynced[player] =
				TableUtils.deepCopy(PlayerDataServer._playerData[player]) :: PlayerData
		else
			-- If this is a session lock error, we want to record a different error type so the client
			-- can display an alternative message to the user
			if result == SessionLockedDataStoreWrapper.sessionLockErrorString then
				errorType = PlayerDataErrorType.SessionLocked
			end

			warn("Error loading player data: " .. tostring(result))

			hasErrored = true
		end
	else
		-- If Data Store access is not permitted, we will treat the load as an error
		hasErrored = true
	end

	if hasErrored then
		-- If the player's data load has errored - we still want to allow them to play the game with default data
		PlayerDataServer._playerData[player] = TableUtils.deepCopy(PlayerDataServer._defaultData) :: PlayerData
		PlayerDataServer._setPlayerDataAsErrored(player, errorType)
	else
		PlayerDataServer._sendLoadedData(player)
	end
end

function PlayerDataServer._setPlayerDataAsErrored(player: Player, errorType: string)
	-- We need to mark their profile as errored so we can disable purchases and prevent their save from being overwritten.

	PlayerDataServer._playerDataLoadErrors[player] = errorType

	PlayerDataServer._sendLoadedData(player)
end

-- Sends a payload to PlayerDataClient including the data loaded and the error type (if there was a failure to load)
function PlayerDataServer._sendLoadedData(player: Player)
	-- We don't want to do anything further if the player has already left
	if not player:IsDescendantOf(Players) then
		return
	end

	-- We want to filter out any values that we have marked as private so they are not replicated to the client
	local data = TableUtils.filter(
		TableUtils.deepCopy(PlayerDataServer._playerData[player]),
		function(_: boolean, valueName: string)
			return not PlayerDataServer._privateValueNames[valueName]
		end
	) :: PlayerData

	local success = not PlayerDataServer.hasLoaded(player)
	local errorType = PlayerDataServer._playerDataLoadErrors[player]

	-- Now the data has loaded, we want to resume any threads that were yielded by PlayerDataServer.waitForDataLoadAsync
	PlayerDataServer._resumeThreadsPendingLoad(player)

	playerDataLoaded:FireClient(player, data, success, errorType)
end

-- Resumes any threads that were yielded by PlayerData:waitForDataLoadAsync()
function PlayerDataServer._resumeThreadsPendingLoad(player: Player)
	if PlayerDataServer._threadsPendingPlayerDataLoad[player] then
		for _, thread in ipairs(PlayerDataServer._threadsPendingPlayerDataLoad[player]) do
			task.spawn(thread)
		end
	end

	PlayerDataServer._threadsPendingPlayerDataLoad[player] = nil
end

-- Performs a final save and removes session data for the player from PlayerDataServer
function PlayerDataServer.onPlayerRemovingAsync(player: Player)
	local canSave = PlayerDataServer.canSave(player)
	local data = PlayerDataServer._playerData[player]

	-- Clear out saved values for this player to avoid memory leaks
	PlayerDataServer._playerData[player] = nil
	PlayerDataServer._playerDataSynced[player] = nil
	PlayerDataServer._playerDataLoadErrors[player] = nil
	PlayerDataServer._playerDataMetadata[player] = nil
	PlayerDataServer._threadsPendingPlayerDataLoad[player] = nil

	if canSave then
		PlayerDataServer._savePlayerDataAsync(player, data, true)
	end
end

-- In some cases, we may wish to prompt a save from outside of the auto-save loop
-- For example, after a purchase we may wish to save straight away
-- Returns success, result
function PlayerDataServer.saveDataAsync(player: Player)
	assert(PlayerDataServer.canSave(player), "Player data cannot currently be saved")

	local data = PlayerDataServer._playerData[player]

	return PlayerDataServer._savePlayerDataAsync(player, data, false)
end

function PlayerDataServer._getKey(player: Player)
	return tostring(player.UserId)
end

function PlayerDataServer._savePlayerDataAsync(player: Player, data: any, unlockAfter: boolean)
	local setOptions = PlayerDataServer._getDataStoreSetOptions(player)
	local dataSubmitted = TableUtils.deepCopy(data)

	local success, result = PlayerDataServer._sessionLockedWrapper:setAsync(
		PlayerDataServer._getKey(player),
		data,
		{ player.UserId },
		setOptions,
		{
			unlockAfter = unlockAfter,
			expiryTime = AUTO_SAVE_INTERVAL * 2, -- We want our lock to expire long after the auto save interval to ensure the lock isn't lifted during a session
		}
	)

	if not success then
		-- As the player's data has failed to save this could be a data loss scenario!
		warn("Failed to save player data: " .. tostring(result))
	end

	-- Inform the client about whether the data has saved successfully
	if player:IsDescendantOf(Players) then
		local errorType
		if not success then
			errorType = PlayerDataErrorType.DataStoreError

			if result == SessionLockedDataStoreWrapper.sessionLockErrorString then
				errorType = PlayerDataErrorType.SessionLocked
			end
		end

		playerDataSaved:FireClient(player, success, errorType)
	end

	if success then
		PlayerDataServer._playerDataSynced[player] = dataSubmitted
	end

	return success, result
end

-- Returns the DataStoreSetOptions to be used by the underlying DataStoreService methods,
-- including the metadata
function PlayerDataServer._getDataStoreSetOptions(player: Player): DataStoreSetOptions
	local metadata = PlayerDataServer._playerDataMetadata[player] or {}
	local setOptions = Instance.new("DataStoreSetOptions")
	setOptions:SetMetadata(metadata)

	return setOptions
end

-- Returns if it is safe to save the player's data
function PlayerDataServer.canSave(player: Player)
	if not dataStoresEnabled then
		return false
	end

	if not PlayerDataServer.hasLoaded(player) then
		return false
	end

	if PlayerDataServer.hasErrored(player) then
		return false
	end

	return true
end

-- Save every player's data in parallel
function PlayerDataServer._saveAllPlayerData(unlockAfter: boolean)
	for player, data in pairs(PlayerDataServer._playerData) do
		if PlayerDataServer.canSave(player) then
			task.spawn(PlayerDataServer._savePlayerDataAsync, player, data, unlockAfter)
		end
	end
end

function PlayerDataServer._bindSavingToGameClose()
	-- We don't want BindToClose behavior in Studio as it hurts play-test iteration time
	if not dataStoresEnabled then
		return
	end

	game:BindToClose(function()
		-- We'd expect every player to have left already before the server closes, but
		-- in some cases this may not be true (for example, a manual shutdown prompted
		-- by the developer). For this reason, we need to save whatever data is currently
		-- loaded in the server.
		PlayerDataServer._saveAllPlayerData(true)

		-- As we only have a limited amount of time before the server closes, we do not
		-- want to expend time processing out-of-date requests
		PlayerDataServer._sessionLockedWrapper:skipAllQueuesToLastEnqueued()

		-- We don't want to let this thread die until all saving has completed.
		while not PlayerDataServer._sessionLockedWrapper:areAllQueuesEmpty() do
			task.wait(0)
		end
	end)
end

function PlayerDataServer._startAutoSaveLoop()
	setInterval(function()
		PlayerDataServer._saveAllPlayerData(false)
	end, AUTO_SAVE_INTERVAL)
end

return PlayerDataServer
