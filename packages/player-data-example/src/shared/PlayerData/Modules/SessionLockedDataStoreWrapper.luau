--!strict

--[[
	Meta-wrapper for DataStoreWrapper that provides session locking functionality

	When in use, a DataStore key is 'owned' by a session and can only be 'owned' by one session at a time. This means when the key is first loaded
	by the server, the server will set metadata on the key to mark that it is currently in use. Any subsequent attempts by other servers to load or
	update this key will fail, until the original server relinquishes control using the 'unlockAfter' lock setting. Locks placed on DataStore keys
	need to be actively maintained with continued updates, and will expire after an expiry time if this is not done.

	Session locking is particularly useful for avoiding race conditions in player data, when a player joins a new server before the old server has
	finished saving their data.
--]]

local HttpService = game:GetService("HttpService")

local noYield = require(script.Parent.Parent.noYield)
local DataStoreWrapper = require(script.Parent.DataStoreWrapper)
local mergeArraysUniqueOnly = require(script.Parent.mergeArraysUniqueOnly)
local TableUtils = require(script.Parent.TableUtils)

local DEFAULT_LOCK_SETTINGS = {
	expiryTime = 360,
	overwriteLock = false,
	unlockAfter = false,
}

local DATA_STORE_REQUEST_COOLDOWN_CONSTANT = 5
local DATA_STORE_REQUEST_COOLDOWN_EXPONENT = 5
local DATA_STORE_REQUEST_ATTEMPTS = 3
local NIL_STRING_PLACEHOLDER = "<nil>"

type TransformCallback = (any, DataStoreKeyInfo) -> (any, { number }?, { [string]: any }?)
type LockSettings = {
	expiryTime: number,
	overwriteLock: boolean?,
	unlockAfter: boolean?,
}

local SessionLockedDataStoreWrapper = {}
SessionLockedDataStoreWrapper.__index = SessionLockedDataStoreWrapper
SessionLockedDataStoreWrapper.sessionLockErrorString = "SessionLockError"

export type ClassType = typeof(setmetatable(
	{} :: {
		_name: string,
		_baseWrapper: DataStoreWrapper.ClassType,
		_lockedKeysLastUpdated: { [string]: number },
		_activeLockIds: { [string]: string },
	},
	SessionLockedDataStoreWrapper
))

function SessionLockedDataStoreWrapper.new(
	name: string,
	maxAttempts: number?,
	retryConstant: number?,
	retryExponent: number?
): ClassType
	maxAttempts = maxAttempts or DATA_STORE_REQUEST_ATTEMPTS
	retryConstant = retryConstant or DATA_STORE_REQUEST_COOLDOWN_CONSTANT
	retryExponent = retryExponent or DATA_STORE_REQUEST_COOLDOWN_EXPONENT

	local self = {
		_name = name,
		_baseWrapper = DataStoreWrapper.new(name, maxAttempts, retryConstant, retryExponent),
		_lockedKeysLastUpdated = {},
		_activeLockIds = {},
	}

	setmetatable(self, SessionLockedDataStoreWrapper)

	return self
end

-- Uses the keyInfo provided in the DataStore:UpdateAsync callback to determine if the
-- key is safe to update given the wrapper's knowledge of locks it maintains and the
-- lockSettings
function SessionLockedDataStoreWrapper._isKeySafeToUpdate(
	self: ClassType,
	key: string,
	lockSettings: LockSettings,
	optionalKeyInfo: DataStoreKeyInfo?
): boolean
	-- If there is no metadata, the key has never been written to and is safe to access
	if not optionalKeyInfo then
		return true
	end

	local keyInfo = optionalKeyInfo :: DataStoreKeyInfo
	local metadata: { [string]: any } = keyInfo:GetMetadata()

	if self._activeLockIds[key] then
		-- If this server has locked this key, we need to verify the lock is still in place
		if self._activeLockIds[key] ~= metadata.lockId then
			-- Not safe to update. This server had a lock on this key, but this lock was evicted by another server.
			-- This could be due to developer error (not updating the key frequently enough) or due to an outage in
			-- DataStoreService or the game server. If we were to proceed with updating the key here we could be overwriting
			-- newer data.
			return false
		end
	elseif metadata.lockId then
		-- Locked keys should be refreshed regularly, if the key hasn't been updated in some time
		-- we can assume the server with the active session is finished but has failed to unlock (crashed, or bad implementation)
		if os.difftime(os.time(), keyInfo.UpdatedTime / 1000) > lockSettings.expiryTime then
			-- Safe to update. There is a lock on this key, but it has expired.
			return true
		else
			-- Not safe to update. Another sever has placed a lock on this key, and this lock has not expired.
			return false
		end
	end

	-- Safe to proceed. No lock is present on the key and this server has not had its own lock evicted.
	return true
end

-- Appends to a DataStore key metadata table a unique lock identifier
function SessionLockedDataStoreWrapper._lockMetadata(
	self: ClassType,
	key: string,
	metadata: { [any]: any }
): { [any]: any }
	local existingLockId = self._activeLockIds[key]

	-- We only need to generate a new lock identifier if it hasn't already been set
	if not metadata.lockId or metadata.lockId ~= existingLockId then
		return TableUtils.merge(metadata, { lockId = HttpService:GenerateGUID() })
	end

	return metadata
end

-- Removes the lock identifier from the metadata table
function SessionLockedDataStoreWrapper._unlockMetadata(self: ClassType, metadata: { [any]: any }): { [any]: any }
	return TableUtils.merge(metadata, { lockId = TableUtils.NoValue })
end

-- All DataStore requests in SessionLockedDataStoreWrapper are routed via _requestAsync
function SessionLockedDataStoreWrapper._requestAsync(
	self: ClassType,
	key: string,
	transformCallback: TransformCallback,
	optionalLockSettings: LockSettings?
): (boolean, string | any, DataStoreKeyInfo?)
	local lockSettings = TableUtils.merge(DEFAULT_LOCK_SETTINGS, optionalLockSettings) :: LockSettings
	local lockTime = os.clock()

	local keyWasSafeToUpdate = true

	-- Session locking requires _everything_ is routed through UpdateAsync calls so that the key can be
	-- read AND written atomically. This allows us to verify the key is safe to write to, and write to it
	-- at the same time.
	local success, result: any, keyInfo = self._baseWrapper:updateAsync(
		key,
		function(currentValue: any, currentKeyInfo: DataStoreKeyInfo?)
			-- If the key is deemed 'unsafe' to write to, we only want to proceed when lockSettings.overwriteLock is true
			if not self:_isKeySafeToUpdate(key, lockSettings, currentKeyInfo) and not lockSettings.overwriteLock then
				keyWasSafeToUpdate = false
				return nil
			end

			-- Substitute stand-ins for nil with an actual nil value (see comment below)
			if currentValue == NIL_STRING_PLACEHOLDER then
				currentValue = nil
			end

			-- To prevent race conditions we do not allow transformCallback to yield
			local value, userIds, metadata = noYield(transformCallback, currentValue, currentKeyInfo)
			metadata = metadata or {}

			-- We cannot return nil or the key metadata will not be updated, so instead we will use a stand-in
			-- string that we will substitute for nil later
			if value == nil then
				value = NIL_STRING_PLACEHOLDER
			end

			-- We want to release our lock on the key if lockSettings.unlockAfter is true, or ensure it is in place
			-- if it is not
			if lockSettings.unlockAfter then
				metadata = self:_unlockMetadata(metadata)
			else
				metadata = self:_lockMetadata(key, metadata)
			end

			return value, userIds, metadata
		end,
		-- DataStoreWrapper allows us to include a custom handler that will be used to call the
		-- DataStore function in place of pcall. We need that here so we can still retry if the
		-- DataStore operation worked but the key was not safe to update
		function(operation)
			local operationSuccess, operationResult, operationKeyInfo = pcall(operation)

			if not keyWasSafeToUpdate then
				operationSuccess = false
				operationResult = self.sessionLockErrorString
			end

			return operationSuccess, operationResult, operationKeyInfo
		end
	)

	if success then
		-- Substitute nil stand-in for actual nil value (see comment above)
		if result == NIL_STRING_PLACEHOLDER then
			result = nil
		end

		local metadata = if keyInfo then keyInfo:GetMetadata() else nil
		local lockId = if metadata then metadata.lockId else nil

		if lockId then
			self:_storeLock(key, lockId, lockTime, lockSettings)
		else
			self:_forgetLock(key)
		end
	else
		-- We will surface a unique error string for session lock errors so the player can be shown a distinct message
		-- The raw error value from an error thrown in the transform function of UpdateAsync is not passed, so instead we
		-- will search for it in the errorMessage. This is brittle and vulnerable for how Roblox changes the errorMessage
		-- DataStore:UpdateAsync returns when the transform function errors.
		if string.find(tostring(result), self.sessionLockErrorString) then
			result = self.sessionLockErrorString
		end
	end

	return success, result, keyInfo
end

-- Store a record of the lock in memory so we can detect cases when a lock this server
-- has placed has been removed when updating a key
function SessionLockedDataStoreWrapper._storeLock(
	self: ClassType,
	key: string,
	lockId: string,
	lockTime: number,
	lockSettings: LockSettings
)
	self._activeLockIds[key] = lockId

	self:_warnIfLockNotMaintained(key, lockId, lockTime, lockSettings)
end

-- Schedule a warning if the lock has not been removed or updated before its due to expire as this should
-- almost always be avoided in production code
function SessionLockedDataStoreWrapper._warnIfLockNotMaintained(
	self: ClassType,
	key: string,
	lockId: string,
	lockTime: number,
	lockSettings: LockSettings
)
	self._lockedKeysLastUpdated[key] = lockTime

	task.delay(lockSettings.expiryTime, function()
		if not self._activeLockIds[key] or self._activeLockIds[key] ~= lockId then
			-- If we have already removed this lock or replaced it with another one, we do not need to warn
			return
		end

		if self._lockedKeysLastUpdated[key] and self._lockedKeysLastUpdated[key] == lockTime then
			warn(
				string.format(
					"Key %s in DataStore %s was locked but not explicitly unlocked or the lock refreshed within the expiryTime.",
					key,
					self._name
				)
			)
		end
	end)
end

-- Remove a key's lock identifier and updated time from memory
function SessionLockedDataStoreWrapper._forgetLock(self: ClassType, key: string)
	self._lockedKeysLastUpdated[key] = nil
	self._activeLockIds[key] = nil
end

function SessionLockedDataStoreWrapper.updateAsync(
	self: ClassType,
	key: string,
	transformCallback: TransformCallback,
	lockSettings: LockSettings?
): (boolean, string | any)
	return self:_requestAsync(key, transformCallback, lockSettings)
end

-- Refreshes the lock this server has on a key by updating the key without changing its value
-- This should be called every lockSettings.expiryTime seconds unless another request is made
function SessionLockedDataStoreWrapper.refreshLockAsync(self: ClassType, key: string): (boolean, string?)
	return self:_requestAsync(key, function(value: any, keyInfo: DataStoreKeyInfo)
		local userIds = if keyInfo then keyInfo:GetUserIds() else nil
		local metadata = if keyInfo then keyInfo:GetMetadata() else nil

		return value, userIds, metadata
	end)
end

function SessionLockedDataStoreWrapper.getAsync(
	self: ClassType,
	key: string,
	lockSettings: LockSettings?,
	userIdsToInclude: { number }?
): (boolean, any | string, DataStoreKeyInfo?)
	return self:_requestAsync(key, function(value: any, keyInfo: DataStoreKeyInfo)
		local userIds = if keyInfo then keyInfo:GetUserIds() else nil
		local metadata = if keyInfo then keyInfo:GetMetadata() else nil

		-- Although this is a get request, as this get actually saves, we need to make sure we
		-- are writing to the userIds list for compliance reasons
		local oldUserIds = userIds or {}

		if userIdsToInclude then
			userIds = mergeArraysUniqueOnly(oldUserIds :: { number }, userIdsToInclude)
		end

		return value, userIds, metadata
	end, lockSettings)
end

function SessionLockedDataStoreWrapper.setAsync(
	self: ClassType,
	key: string,
	value: any,
	userIds: { number }?,
	options: DataStoreSetOptions?,
	lockSettings: LockSettings?
): (boolean, string?)
	return self:_requestAsync(key, function()
		local metadata = if options then options:GetMetadata() else nil

		return value, userIds, metadata
	end, lockSettings)
end

function SessionLockedDataStoreWrapper.areAllQueuesEmpty(self: ClassType): boolean
	return self._baseWrapper:areAllQueuesEmpty()
end

function SessionLockedDataStoreWrapper.getQueueLength(self: ClassType, key: string): number
	return self._baseWrapper:getQueueLength(key)
end

-- See caveat comment in DataStoreWrapper:skipAllQueuesToLastEnqueued()
function SessionLockedDataStoreWrapper.skipAllQueuesToLastEnqueued(self: ClassType)
	self._baseWrapper:skipAllQueuesToLastEnqueued()
end

return SessionLockedDataStoreWrapper
