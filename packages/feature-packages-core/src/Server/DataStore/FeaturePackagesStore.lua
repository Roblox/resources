--!strict

--[[
	Wrapper around DataStore used by FeaturePackages to store and retrieve data.
	
	Using this module will help reduce the number of DataStore calls made by the game, as it caches the data locally.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Protect the run context, this ModuleScript is only intended to run on the server
require(ReplicatedStorage.FeaturePackagesCore.Modules.ProtectRunContext).server()

local Players = game:GetService("Players")

local SharedConstants = require(ReplicatedStorage.FeaturePackagesCore.Configs.SharedConstants)
local DataStoreTypes = require(ReplicatedStorage.FeaturePackagesCore.Configs.DataStoreTypes)
local DataStoreWrapper = require(script.Parent.DataStoreWrapper)

local DATA_STORE_REQUEST_ATTEMPTS = 3
local DATA_STORE_REQUEST_COOLDOWN_CONSTANT = 5
local DATA_STORE_REQUEST_COOLDOWN_EXPONENT = 5

-- Local variables shared across the module
local dataStoreWrapper = DataStoreWrapper.new(
	SharedConstants.Stores.FeaturePackages.NAME,
	DATA_STORE_REQUEST_ATTEMPTS,
	DATA_STORE_REQUEST_COOLDOWN_CONSTANT,
	DATA_STORE_REQUEST_COOLDOWN_EXPONENT
)

local cache: { [string]: DataStoreTypes.FeaturePackagesData } = {}

local dataCallbacks: { [DataStoreTypes.TableId]: DataStoreTypes.DataCallback } = {}
local initializeCallbacks: { [DataStoreTypes.TableId]: DataStoreTypes.DataCallback } = {}

local readLock = false

local FeaturePackagesStore = {}

local function getKeyForPlayer(player: Player, suffix: string?): string
	return `{player.UserId}{suffix or SharedConstants.Stores.FeaturePackages.SUFFIX}`
end

local function getPlayerFromKey(key: string, suffix: string?): Player?
	local playerId = tonumber(key:sub(1, key:len() - (suffix or SharedConstants.Stores.FeaturePackages.SUFFIX):len()))
	if not playerId then
		return nil
	end
	return Players:GetPlayerByUserId(playerId)
end

local function onTableInitialize(player: Player)
	local key = getKeyForPlayer(player)
	local table = cache[key]

	-- If there is an onInitializeCallback for the table, call it to make sure the data is initialized
	for tableId, callback in pairs(initializeCallbacks) do
		local cachedTableData = table.Tables[tableId]

		table.Tables[tableId] = callback(player, cachedTableData) -- Allow table owner to mutate data

		-- If the data was replaced, call the onSaveCallback for the handler in cache mode
		if cachedTableData ~= table.Tables[tableId] then
			local modifyCallback = dataCallbacks[tableId]
			if modifyCallback then
				table.Tables[tableId] = modifyCallback(player, table.Tables[tableId], false)
			end
		end
	end
end

local function getFeaturePackagesStore(player: Player): DataStoreTypes.FeaturePackagesData
	-- Wait for any concurrent reads to finish.
	while readLock do
		task.wait()
	end

	readLock = true
	local key = getKeyForPlayer(player)

	-- If the data is cached, return it
	if cache[key] then
		readLock = false
		return cache[key]
	end

	-- Otherwise, get the data from the data store
	local success, result = dataStoreWrapper:getAsync(key)

	-- If the data has already been fetched by a parallel request, do not overwrite the cache just return it.
	if cache[key] then
		warn(`Duplicate DataStore fetch for {key}, cached version already exists.`)
		readLock = false
		return cache[key]
	end

	-- If data is not in cache and cannot be retrieved from data store, return nil
	if not success then
		error(`Failed to get FeaturePackages store for {key} because {result}`)
	end

	-- Cache the data
	if result then
		cache[key] = result :: DataStoreTypes.FeaturePackagesData
	else
		-- Return an empty table if no data is found
		-- Save it in cache to initialize it.
		cache[key] = { Tables = {} } :: DataStoreTypes.FeaturePackagesData
	end

	readLock = false

	-- Data for the player was read for the first time, call init handlers
	onTableInitialize(player)

	return cache[key]
end

local function onPlayerRemoving(player: Player)
	local key = getKeyForPlayer(player)

	-- Save player data for all tables
	local newData = cache[key] or { Tables = {} } :: DataStoreTypes.FeaturePackagesData
	for tableId, callback in pairs(dataCallbacks) do
		if not callback then
			continue
		end

		-- If there is an onSaveCallback for the table, call it to make sure we save the latest data
		local cachedTableData = newData.Tables[tableId]
		newData.Tables[tableId] = callback(player, cachedTableData, true) -- Allow table owner to mutate data
	end

	-- Now save the entire data to the data store
	dataStoreWrapper:setAsync(key, newData)

	-- Clear cached data for player since they are leaving
	cache[key] = nil
end

local function bindToClose()
	-- As we only have a limited amount of time before the server closes, we do not
	-- want to expend time processing out-of-date requests
	dataStoreWrapper:skipAllQueuesToLastEnqueued()

	-- We don't want to let this thread die until all saving has completed.
	while not dataStoreWrapper:areAllQueuesEmpty() do
		task.wait(0)
	end
end

-- Checks if there is legacy data for the player in a legacy table and migrates it to the new table
-- If there is no legacy data, returns nil
-- If there is legacy data, returns the data that was migrated
-- This method will error if the migration fails
local function checkAndMigrateLegacyData(player: Player, tableId: DataStoreTypes.TableId): any?
	local legacyTableConstants = SharedConstants.Stores.LEGACY[tableId]
	if not legacyTableConstants then
		return nil -- This table did not exist in the legacy constants
	end

	-- Check to see if the player has existing data in the legacy table
	local legacyKey = getKeyForPlayer(player, legacyTableConstants.SUFFIX)
	local legacyDataStoreWrapper = DataStoreWrapper.new(
		legacyTableConstants.NAME,
		DATA_STORE_REQUEST_ATTEMPTS,
		DATA_STORE_REQUEST_COOLDOWN_CONSTANT,
		DATA_STORE_REQUEST_COOLDOWN_EXPONENT
	)

	local success, result = legacyDataStoreWrapper:getAsync(legacyKey)

	if not success then
		-- If the get fails, then we cannot migrate the data
		error(`Failed to migrate data for {legacyKey} because {result}`)
	end

	if not result then
		return nil -- The player did not have data in the legacy table
	end

	-- Handle init callbacks for the legacy data
	local callback = initializeCallbacks[tableId]

	if callback then
		result = callback(player, result) -- Allow table owner to mutate data

		-- Call the onSaveCallback for the handler
		local modifyCallback = dataCallbacks[tableId]
		if modifyCallback then
			result = modifyCallback(player, result, false)
		end
	end

	-- Save the data to the new table
	local saveSuccess = FeaturePackagesStore.setAsync(player, tableId, result)

	if not saveSuccess then
		-- If the save fails, then we cannot migrate the data
		error(`Failed to save legacy data into new table for {legacyKey}`)
	end

	-- Clear the legacy data
	print(`Migrated legacy data for {legacyKey} to new table {tableId} successfully`)
	legacyDataStoreWrapper:removeAsync(legacyKey)

	return result
end

function FeaturePackagesStore.getAsync(player: Player, tableId: DataStoreTypes.TableId): any
	local featurepackagesData = getFeaturePackagesStore(player)

	if not featurepackagesData or not featurepackagesData.Tables[tableId] then
		-- There is no data for the player or the player had data but not for the specific table
		-- Let's check if there is legacy data that needs to be migrated
		local migratedData = checkAndMigrateLegacyData(player, tableId)
		return migratedData
	end

	return featurepackagesData.Tables[tableId]
end

function FeaturePackagesStore.setAsync(
	player: Player,
	tableId: DataStoreTypes.TableId,
	data: any,
	onlySaveToCache: boolean?
): boolean
	local key = getKeyForPlayer(player)

	-- Data owner callback
	local newData = data
	if dataCallbacks[tableId] then
		newData = dataCallbacks[tableId](player, data) -- Allow table owner to mutate data
	end

	local featurepackagesData = getFeaturePackagesStore(player)
	featurepackagesData.Tables[tableId] = newData -- Overwrite the sub-table with the new data

	if onlySaveToCache then
		-- If onlySaveToCache is true, only save to cache and do not save to data store
		-- This will rely on the server shutting down gracefully to save the data or a subsequent call to setAsync without onlySaveToCache
		cache[key] = featurepackagesData :: DataStoreTypes.FeaturePackagesData
		return true
	end

	-- Attempt to set the data in the data store.
	local success, result = dataStoreWrapper:setAsync(key, featurepackagesData)

	-- If data cannot be set in data store, return false
	if not success then
		warn(`Failed to set FeaturePackages store for {key} because {result}`)
		return false
	end

	-- Cache the data
	if success then
		cache[key] = featurepackagesData :: DataStoreTypes.FeaturePackagesData
	end

	return true
end

function FeaturePackagesStore.removeAsync(player: Player, tableId: DataStoreTypes.TableId?): boolean
	local key = getKeyForPlayer(player)

	-- If a specific table is provided, clear only that table from FeaturePackagesStore
	if tableId then
		local featurepackagesData = getFeaturePackagesStore(player)

		if not featurepackagesData.Tables[tableId] then
			-- If the table does not exist, nothing to remove
			return true
		end

		featurepackagesData.Tables[tableId] = nil

		local success, result = dataStoreWrapper:setAsync(key, featurepackagesData)

		if not success then
			warn(`Failed to remove {key} from table {tableId} because {result}`)
			return false
		end

		return success
	end

	-- Otherwise, remove the entire data from data store
	local success, result = dataStoreWrapper:removeAsync(key)

	-- If data cannot be removed in data store, return false
	if not success then
		warn(`Failed to remove FeaturePackages store data for {key} because {result}`)
		return false
	end

	-- Cache the data
	if success then
		cache[key] = nil
	end

	return true
end

function FeaturePackagesStore.bindToTransform(tableId: DataStoreTypes.TableId, callback: DataStoreTypes.DataCallback)
	dataCallbacks[tableId] = callback
end

function FeaturePackagesStore.bindToInitialize(tableId: DataStoreTypes.TableId, callback: DataStoreTypes.DataCallback)
	initializeCallbacks[tableId] = callback

	for playerKey in pairs(cache) do
		local player = getPlayerFromKey(playerKey)
		if not player then
			continue
		end

		onTableInitialize(player)
	end
end

local function initialize()
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	game:BindToClose(function()
		for _, player in ipairs(game.Players:GetPlayers()) do
			onPlayerRemoving(player)
		end

		bindToClose()
	end)
end

initialize()

return FeaturePackagesStore
