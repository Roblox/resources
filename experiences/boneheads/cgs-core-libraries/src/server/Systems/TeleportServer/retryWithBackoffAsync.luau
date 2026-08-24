-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

type RetryConfig = {
	read maxRetries: number,
	read initialBackoffSeconds: number,
	read maxBackoffSeconds: number,
	read backoffMultiplier: number,
}

local random = Random.new()

local function retryWithBackoffAsync(
	operation: () -> (),
	shouldCancel: () -> boolean,
	onAttempt: (attemptNumber: number) -> (),
	onRetrying: (attemptNumber: number, errorMessage: string) -> (),
	retryConfig: RetryConfig
): (boolean, string?, number)
	local backoffSeconds = retryConfig.initialBackoffSeconds
	local lastAttempt = 0

	for attempt = 1, retryConfig.maxRetries do
		if shouldCancel() then
			return false, "Cancelled", lastAttempt
		end

		lastAttempt = attempt
		onAttempt(attempt)

		local ok, err = pcall(operation)
		if ok then
			return true, nil, attempt
		end

		local errorMessage = if typeof(err) == "string" then err else tostring(err)

		if attempt >= retryConfig.maxRetries then
			return false, errorMessage, attempt
		end

		onRetrying(attempt, errorMessage)

		-- Exponential backoff with jitter
		local jitteredDelay = backoffSeconds * (0.5 + random:NextNumber() * 0.5)
		task.wait(jitteredDelay)

		backoffSeconds = math.min(backoffSeconds * retryConfig.backoffMultiplier, retryConfig.maxBackoffSeconds)
	end

	return false, "Max retries exhausted", lastAttempt
end

return retryWithBackoffAsync
