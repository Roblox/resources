--!strict

local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local CodeStatus = require(script.Parent.CodeStatus)
local Constants = require(script.Parent.Constants)
local LeaderElection = require(script.Parent.LeaderElection)
local getItemsFitting = require(script.Parent.getItemsFitting)
local retryAsync = require(script.Parent.retryAsync)

type CodeStatusMap = { [string]: string }

local Manager = {}
Manager.__index = Manager

function Manager.new(key: string)
	local dataStore = DataStoreService:GetDataStore(string.format(Constants.DATA_STORE_NAME_TEMPLATE, key))
	local memoryStore = MemoryStoreService:GetSortedMap(string.format(Constants.MEMORY_STORE_NAME_TEMPLATE, key))

	local self = {
		_dataStore = dataStore,
		_memoryStore = memoryStore,
		_key = key,
	}
	setmetatable(self, Manager)
	return self
end

-- Read a list of codes from the specified MemoryStore key
function Manager:_getCodesFromMemoryAsync(key: string): { string }
	local memoryStore = self._memoryStore :: MemoryStoreSortedMap

	local success, result = pcall(function()
		return memoryStore:GetAsync(key)
	end)

	if success then
		return result
	else
		warn(`Failed to get {key} codes from MemoryStore because: {result}`)
		return {}
	end
end

-- Remove a list of codes from the specified MemoryStore key
function Manager:_removeCodesFromMemoryAsync(key: string, codes: { string })
	local memoryStore = self._memoryStore :: MemoryStoreSortedMap

	local success, result = pcall(function()
		memoryStore:UpdateAsync(key, function(oldData): { string }?
			if not oldData then
				-- If no data currently exists in the key, then there's nothing to remove.
				-- It's okay to treat this as a success since the codes are technically 'removed'.
				-- This shouldn't normally happen, since codes are only removed once they have been read first.
				-- If the key *was* entirely wiped since the last read, something has gone horribly wrong, so we'll throw a warning.
				warn(`Attempted to remove codes from {key}, but no data exists`)
				return nil
			end
			local newData = oldData :: { string }

			for _, code in codes do
				local index = table.find(newData, code)
				if index then
					table.remove(newData, index)
				end
			end

			return newData
		end, Constants.MEMORY_STORE_EXPIRATION)
	end)

	if not success then
		warn(`Failed to remove {key} codes from MemoryStore because: {result}`)
	end
end

-- Save used and released codes into DataStore using a 3 step process:
-- Step 1: Read codes from Used and Released MemoryStore keys
-- Step 2: Update code statuses in DataStore
-- Step 3: Remove codes that were updated in DataStore from MemoryStore
-- This process ensures that the minimal amount of codes are lost (i.e. stuck in a Reserved state) in case of a DataStore or MemoryStore failure
function Manager:_saveUsedAndReleasedCodesAsync(): (boolean, string?)
	local dataStore = self._dataStore :: GlobalDataStore

	-- Step 1: Read codes from Used and Released MemoryStore keys
	local usedCodes: { string } = self:_getCodesFromMemoryAsync(Constants.MEMORY_STORE_USED_KEY)
	local releasedCodes: { string } = self:_getCodesFromMemoryAsync(Constants.MEMORY_STORE_RELEASED_KEY)

	if #usedCodes == 0 and #releasedCodes == 0 then
		return true
	end

	-- Step 2: Update code statuses in DataStore with a single UpdateAsync call
	local updateDataSuccess, updateDataResult = retryAsync(function()
		dataStore:UpdateAsync(Constants.DATA_STORE_CODES_KEY, function(oldData): CodeStatusMap?
			if not oldData then
				warn(`DataStore for {self._key} has not been initialized!`)
				return nil
			end
			local newData = oldData :: CodeStatusMap

			for _, code in usedCodes do
				if newData[code] == CodeStatus.Used then
					warn(`Attempted to mark a code as Used twice: {code}`)
				else
					newData[code] = CodeStatus.Used
				end
			end

			for _, code in releasedCodes do
				if newData[code] == CodeStatus.Used then
					warn(`Attempted to release a Used code: {code}`)
				else
					newData[code] = CodeStatus.Available
				end
			end

			return newData
		end)
	end, Constants.UPDATE_ATTEMPTS, Constants.UPDATE_RETRY_PAUSE_CONSTANT, Constants.UPDATE_RETRY_PAUSE_EXPONENT_BASE)

	if not updateDataSuccess then
		return false, `Failed to update codes in DataStore because: {updateDataResult}`
	end

	-- Step 3: Remove codes that were updated in DataStore from MemoryStore
	self:_removeCodesFromMemoryAsync(Constants.MEMORY_STORE_USED_KEY, usedCodes)
	self:_removeCodesFromMemoryAsync(Constants.MEMORY_STORE_RELEASED_KEY, releasedCodes)

	return true
end

-- Refill the Available MemoryStore codes from DataStore using a 3 step process:
-- Step 1: Read codes from Available MemoryStore key
-- Step 2: Obtain a list of Available codes from DataStore that can fit into the Available MemoryStore, and mark them as Reserved
-- Step 3: Place codes that were updated in DataStore into Available MemoryStore
function Manager:_makeCodesAvailableAsync(): (boolean, string?)
	local memoryStore = self._memoryStore :: MemoryStoreSortedMap
	local dataStore = self._dataStore :: GlobalDataStore

	-- Get new Available codes from DataStore to place in MemoryStore
	local newAvailableCodes: { string } = {}

	local updateDataSuccess, updateDataResult = retryAsync(function()
		-- Read Available codes in MemoryStore
		local availableCodesInMemory: { string } = self:_getCodesFromMemoryAsync(Constants.MEMORY_STORE_AVAILABLE_KEY)

		dataStore:UpdateAsync(Constants.DATA_STORE_CODES_KEY, function(oldData): CodeStatusMap?
			-- When the same key is updated by multiple servers at once, this callback may be called multiple
			-- times in order to resolve correctly. Since we have a variable that was defined outside of this
			-- scope, we need to reset it at the start of each callback.
			newAvailableCodes = {}
			if not oldData then
				warn(`DataStore for {self._key} has not been initialized!`)
				return nil
			end
			local newData = oldData :: CodeStatusMap

			local availableCodes = {}
			for code, status in newData do
				if status == CodeStatus.Available then
					table.insert(availableCodes, code)
				end
			end

			newAvailableCodes =
				getItemsFitting(availableCodesInMemory, availableCodes, Constants.MEMORY_STORE_VALUE_MAX_SIZE)

			if #newAvailableCodes == 0 then
				return nil
			end

			for _, code in newAvailableCodes do
				newData[code] = CodeStatus.Reserved
			end

			return newData
		end)
	end, Constants.UPDATE_ATTEMPTS, Constants.UPDATE_RETRY_PAUSE_CONSTANT, Constants.UPDATE_RETRY_PAUSE_EXPONENT_BASE)

	if not updateDataSuccess then
		return false, `Failed to reserve codes from DataStore because: {updateDataResult}`
	end

	if #newAvailableCodes == 0 then
		return true
	end

	-- Place new Available codes into MemoryStore
	local updateAvailableSuccess, updateAvailableResult = retryAsync(function()
		memoryStore:UpdateAsync(Constants.MEMORY_STORE_AVAILABLE_KEY, function(oldData): { string }?
			if not oldData then
				oldData = {}
			end
			local newData = oldData :: { string }

			-- Move all codes in newAvailableCodes to newData, starting at the index #newData + 1
			table.move(newAvailableCodes, 1, #newAvailableCodes, #newData + 1, newData)

			return newData
		end, Constants.MEMORY_STORE_EXPIRATION)
	end, Constants.UPDATE_ATTEMPTS, Constants.UPDATE_RETRY_PAUSE_CONSTANT, Constants.UPDATE_RETRY_PAUSE_EXPONENT_BASE)

	if not updateAvailableSuccess then
		return false, `Failed to add new Available codes to MemoryStore because: {updateAvailableResult}`
	end

	return true
end

-- Called each update cycle by the leader server
function Manager:_onLeaderUpdate()
	local saveSuccess, saveResult = self:_saveUsedAndReleasedCodesAsync()
	if not saveSuccess then
		warn(saveResult)
	end

	local makeAvailableSuccess, makeAvailableResult = self:_makeCodesAvailableAsync()
	if not makeAvailableSuccess then
		warn(makeAvailableResult)
	end
end

-- Start a Leader Loop to update codes in DataStore and MemoryStore
function Manager:initialize()
	LeaderElection.startLoop(self._key, Constants.LEADER_UPDATE_INTERVAL, function()
		self:_onLeaderUpdate()
	end)
end

return Manager
