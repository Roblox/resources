--!strict

local MemoryStoreService = game:GetService("MemoryStoreService")

local Constants = require(script.Parent.Constants)
local retryAsync = require(script.Parent.retryAsync)
local getItemsFitting = require(script.Parent.getItemsFitting)
local setSequentialInterval = require(script.Parent.setSequentialInterval)

local Reservation = {}
Reservation.__index = Reservation

function Reservation.new(key: string, reserveCount: number)
	local memoryStore = MemoryStoreService:GetSortedMap(string.format(Constants.MEMORY_STORE_NAME_TEMPLATE, key))
	local self = {
		_open = false,
		_key = key,
		_codes = {},
		_usedCodesToRegister = {},
		_reserveCount = reserveCount,
		_clearUpdate = nil :: (() -> nil)?,
		_memoryStore = memoryStore,
	}
	setmetatable(self, Reservation)
	return self
end

-- Reserve Available codes from MemoryStore to be given out by the server
function Reservation:_reserveCodesAsync(numCodesToReserve: number)
	local success, result = retryAsync(function()
		local codes: { string } = {}

		self._memoryStore:UpdateAsync(Constants.MEMORY_STORE_AVAILABLE_KEY, function(oldData)
			-- When the same key is updated by multiple servers at once, this callback may be called multiple
			-- times in order to resolve correctly. Since codes is defined outside of the callback, we reset
			-- it at the start of the callback to make sure there are no issues if it is called multiple times.
			codes = {}
			if not oldData then
				oldData = {}
			end
			local newData = oldData :: { string }

			-- Reserve new codes from the Available MemoryStore
			while #codes < numCodesToReserve and #newData > 0 do
				local code = table.remove(newData, 1) :: string
				table.insert(codes, code)
			end

			return newData
		end, Constants.MEMORY_STORE_EXPIRATION)

		return codes
	end, Constants.UPDATE_ATTEMPTS, Constants.UPDATE_RETRY_PAUSE_CONSTANT, Constants.UPDATE_RETRY_PAUSE_EXPONENT_BASE)

	if success then
		local reservedCodes = result :: { string }
		if #reservedCodes < numCodesToReserve then
			warn(`Failed to retrieve enough codes. Retrieved: {#result}/{numCodesToReserve}`)
		end

		-- Since the MemoryStore successfully updated, it is safe to add the newly reserved codes
		for _, code in reservedCodes do
			table.insert(self._codes, code)
		end

		return true
	else
		return false, `Failed to reserve codes because: {result}`
	end
end

-- Transfer codes to the specified MemoryStore key, removing any that are successfully added from the table that is passed in
function Reservation:_transferCodesToMemoryAsync(key: string, codes: { string }): (boolean, string?)
	if #codes == 0 then
		return true
	end

	local memoryStore = self._memoryStore :: MemoryStoreSortedMap
	local codesToAdd: { string } = {}

	-- This is safe to retry even when called multiple times in a row. The codes table is passed in by reference, so if another
	-- call of this function succeeds and clears it, the current call will see an empty table and return early.
	local success, result = retryAsync(function()
		memoryStore:UpdateAsync(key, function(oldData): { string }?
			-- When the same key is updated by multiple servers at once, this callback may be called multiple
			-- times in order to resolve correctly. Since codesToAdd is defined outside of the callback, we
			-- reset it at the start of the callback to make sure there are no issues if it is called multiple times.
			codesToAdd = table.clone(codes)
			if #codesToAdd == 0 then
				return nil
			end
			if not oldData then
				oldData = {}
			end
			local newData = oldData :: { string }

			-- Make sure we are not placing too much data into the MemoryStore
			codesToAdd = getItemsFitting(newData, codesToAdd, Constants.MEMORY_STORE_VALUE_MAX_SIZE)
			if #codesToAdd == 0 then
				return nil
			end

			for _, code in codesToAdd do
				-- Make sure duplicate codes are not being inserted. This should not happen in normal flow,
				-- if it does then something has gone majorly wrong.
				if table.find(newData, code) then
					warn(`Something bad happened! Attempted to insert duplicate {key} code`)
				else
					table.insert(newData, code)
				end
			end

			return newData
		end, Constants.MEMORY_STORE_EXPIRATION)
	end, Constants.UPDATE_ATTEMPTS, Constants.UPDATE_RETRY_PAUSE_CONSTANT, Constants.UPDATE_RETRY_PAUSE_EXPONENT_BASE)

	if success then
		for _, code in codesToAdd do
			local index = table.find(codes, code)
			if index then
				table.remove(codes, index)
			end
		end

		return true
	else
		return false, `Failed to add {key} codes to MemoryStore because: {result}`
	end
end

-- If the server is running low on codes, reserve new codes from MemoryStore.
-- At the same time, mark any codes that have been used by this server as Used in MemoryStore.
function Reservation:_updateAsync()
	if not self._open then
		return
	end

	local reserveCount = self._reserveCount :: number
	local numCodesToFill = reserveCount - #self._codes
	local minimumCodesForUpdate = math.floor(reserveCount * Constants.MINIMUM_CODES_PERCENT_TO_UPDATE)
	local requiresNewCodes = #self._codes <= minimumCodesForUpdate
	local hasUsedCodesToRegister = #self._usedCodesToRegister > 0

	-- If we do not need more codes and do not have any used codes to register, no need to access MemoryStore
	if not (requiresNewCodes or hasUsedCodesToRegister) then
		return
	end

	if requiresNewCodes then
		local success, result = self:_reserveCodesAsync(numCodesToFill)
		if not success then
			warn(result)
		end
	end

	if hasUsedCodesToRegister then
		local success, result =
			self:_transferCodesToMemoryAsync(Constants.MEMORY_STORE_USED_KEY, self._usedCodesToRegister)
		if not success then
			warn(result)
		end
	end
end

function Reservation:hasCodes(): boolean
	return #self._codes > 0
end

-- Get the next available code that has been reserved by the server, adding it to the list of used codes
function Reservation:getCode(): string
	assert(self:hasCodes(), "No codes available!")
	local code = table.remove(self._codes, 1) :: string
	table.insert(self._usedCodesToRegister, code)
	return code
end

-- Initialize the reservation, starting a loop to reserve Available codes and save Used/Released codes
function Reservation:open()
	assert(not self._open, `Reservation '{self._key}' is already open`)

	task.spawn(function()
		-- setSequentialInterval waits for the interval first before it starts,
		-- so we call self:_updateAsync() to force an update immediately
		self:_updateAsync()
		self._clearUpdate = setSequentialInterval(function()
			self:_updateAsync()
		end, Constants.RESERVATION_UPDATE_INTERVAL)
	end)

	self._open = true
end

-- Reservation closing is specificaly Async in order to block server shutdown until reserved codes have been released
function Reservation:closeAsync()
	if self._clearUpdate then
		self._clearUpdate()
	end

	local releaseSuccess, releaseResult =
		self:_transferCodesToMemoryAsync(Constants.MEMORY_STORE_RELEASED_KEY, self._codes)
	if not releaseSuccess then
		warn(releaseResult)
	end

	local registerUsedSuccess, registerUsedResult =
		self:_transferCodesToMemoryAsync(Constants.MEMORY_STORE_USED_KEY, self._usedCodesToRegister)
	if not registerUsedSuccess then
		warn(registerUsedResult)
	end

	self._open = false
end

return Reservation
