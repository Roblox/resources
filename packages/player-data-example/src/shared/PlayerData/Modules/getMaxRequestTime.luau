--!strict

--[[
	Returns an estimate of the amount of time a data store request could take to complete given the
	number of attempts, retryConstant, retryExponent and a reasonable worst case estimate for how long
	the DataStoreService call might take to complete.

	See DataStoreWrapper and retryAsync for actual retrying implementations.
--]]

local DATA_STORE_REQUEST_TIME = 3

local function getMaxRequestTime(numAttempts: number, retryConstant: number, retryExponent: number)
	local requestTime = 0

	for attemptNumber = 1, numAttempts do
		requestTime += DATA_STORE_REQUEST_TIME

		if attemptNumber > 1 then
			requestTime += retryConstant + (retryExponent ^ attemptNumber)
		end
	end

	return requestTime
end

return getMaxRequestTime
