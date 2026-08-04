--!strict

--[[
	Wrapper for a DataStore that implements automatic retries for failed requests.

	Requests to the same key are queued and scheduled with a ThreadQueue (including retries) to ensure they are
	processed in order. This avoids a common pitfall in DataStore retry implementations where it is possible for a
	retry for an older request to happen after a newer request resulting in outdated data being saved.

	DataStoreWrapper request methods yield until the request (and its retries) have been completed.
--]]

local DataStoreService = game:GetService("DataStoreService")

local retryAsync = require(script.retryAsync)
local ThreadQueue = require(script.ThreadQueue)

local RETRY_CONSTANT_SECONDS = 0
local RETRY_EXPONENT_SECONDS = 0
local MAX_ATTEMPTS = 1

type TransformCallback = (any, DataStoreKeyInfo) -> (any, { number }?, { [string]: any }?)

local dataStoreOptions = Instance.new("DataStoreOptions")
dataStoreOptions:SetExperimentalFeatures({ v2 = true })

local DataStoreWrapper = {}
DataStoreWrapper.__index = DataStoreWrapper

function DataStoreWrapper.new(name: string, maxAttempts: number?, retryConstant: number?, retryExponent: number?)
	local self = {
		_name = name,
		_maxAttempts = maxAttempts or MAX_ATTEMPTS,
		_retryConstant = retryConstant or RETRY_CONSTANT_SECONDS,
		_retryExponent = retryExponent or RETRY_EXPONENT_SECONDS,
		_keyQueues = {},
	}
	setmetatable(self, DataStoreWrapper)

	return self
end

function DataStoreWrapper:_attemptAsync(
	key: string,
	operation: (dataStore: GlobalDataStore) -> nil,
	optionalRetryFunctionHandler: retryAsync.FunctionHandler?
): (boolean, ...any)
	-- As we will be retrying requests that fail, it's important we have a queue mechanism to ensure
	-- each request is processed in order, to avoid race conditions (ie. request 2 completing while
	-- request 1 is waiting to retry). ThreadQueue:submitAsync will yield until the task has
	-- completed, allowing us to use DataStoreWrapper's API asynchronously
	local queue = self._keyQueues[key] :: typeof(ThreadQueue.new())

	if not queue then
		queue = ThreadQueue.new() :: typeof(ThreadQueue.new())
		self._keyQueues[key] = queue
	end

	-- Capture the tuple values in a table
	local queueReturnValues = {
		queue:submitAsync(function()
			return self:_onQueuePop(operation, optionalRetryFunctionHandler)
		end),
	}

	-- Remove empty queues to prevent memory leaks
	if queue:getLength() == 0 then
		self._keyQueues[key] = nil
	end

	-- Return the success, result values from onQueuePop
	return table.unpack(queueReturnValues)
end

function DataStoreWrapper:_onQueuePop(
	operation: (dataStore: GlobalDataStore) -> nil,
	optionalRetryFunctionHandler: retryAsync.FunctionHandler?
): ...any
	-- Capture the tuple values in a table
	-- We are using retryAsync here to retry failed calls with an exponential backoff
	local attemptReturnValues = {
		retryAsync(function()
			local dataStore = self:getDataStore()

			return operation(dataStore)
		end, self._maxAttempts, self._retryConstant, self._retryExponent, optionalRetryFunctionHandler),
	}

	-- retryAsync returns follow the protected call pattern (success, ...)
	local attemptSuccess = table.remove(attemptReturnValues, 1) :: boolean

	-- ThreadQueue calls tasks with pcall, so rather than returning the success, result
	-- pattern here we will throw when success is false
	if not attemptSuccess then
		-- Attempt failed, bubble the error up through the ThreadQueue
		local errorMessage = attemptReturnValues[1]
		error(errorMessage)
	end

	-- Attempt succeeded, return all values in the result tuple
	return table.unpack(attemptReturnValues)
end

function DataStoreWrapper:getAsync(
	key: string,
	optionalRetryFunctionHandler: retryAsync.FunctionHandler?
): (boolean, any | string, DataStoreKeyInfo?)
	return self:_attemptAsync(key, function(dataStore: GlobalDataStore)
		return dataStore:GetAsync(key)
	end, optionalRetryFunctionHandler)
end

function DataStoreWrapper:setAsync(
	key: string,
	value: any,
	userIds: { number }?,
	options: DataStoreSetOptions?,
	optionalRetryFunctionHandler: retryAsync.FunctionHandler?
): (boolean, string?)
	return self:_attemptAsync(key, function(dataStore: GlobalDataStore)
		return dataStore:SetAsync(key, value, userIds, options)
	end, optionalRetryFunctionHandler)
end

function DataStoreWrapper:removeAsync(
	key: string,
	optionalRetryFunctionHandler: retryAsync.FunctionHandler?
): (boolean, any | string, DataStoreKeyInfo?)
	return self:_attemptAsync(key, function(dataStore: GlobalDataStore)
		return dataStore:RemoveAsync(key)
	end, optionalRetryFunctionHandler)
end

function DataStoreWrapper:updateAsync(
	key: string,
	transformFunction: TransformCallback,
	optionalRetryFunctionHandler: retryAsync.FunctionHandler?
): (boolean, any | string, DataStoreKeyInfo?)
	return self:_attemptAsync(key, function(dataStore: GlobalDataStore)
		return dataStore:UpdateAsync(key, transformFunction)
	end, optionalRetryFunctionHandler)
end

function DataStoreWrapper:getDataStore(): GlobalDataStore
	return DataStoreService:GetDataStore(self._name, nil, dataStoreOptions)
end

function DataStoreWrapper:getQueueLength(key: string): number
	local length = 0
	local threadQueue = self._keyQueues[key]

	if threadQueue then
		length = threadQueue:getLength()
	end

	return length
end

function DataStoreWrapper:areAllQueuesEmpty(): boolean
	for _, threadQueue in pairs(self._keyQueues) do
		if threadQueue:getLength() > 0 then
			return false
		end
	end

	return true
end

-- Code bound to game closure (game:BindToClose) has a limited duration in which to run before timing out.
-- The skipAllQueuesToLastEnqueued method can be used to skip all threadQueues to the most
-- recent request so time isn't wasted on out of date requests. Note, this method will discard
-- the yielded threads stored in the threadQueue meaning DataStoreWrapper calls for these
-- outdated requests will not return. For this reason, only use skipAllQueuesToLastEnqueued during
-- game closure.
function DataStoreWrapper:skipAllQueuesToLastEnqueued()
	for _, threadQueue in pairs(self._keyQueues) do
		threadQueue:skipToLastEnqueued()
	end
end

return DataStoreWrapper
