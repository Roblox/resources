--!strict

local retryAsync = require(script.Parent.Parent.retryAsync)

--[[
	The retry flow for these values of 3, 1, and 2 look like:

	Initial attempt: Instant (failure)

	Retry 1:
		wait 3  (1 + 2^1)
		attempt 2 (failure)

	Retry 2:
		wait 5  (1 + 2^2)
		attempt 3 (failure)

	Accept failure
--]]

local MAX_ATTEMPTS = 3 -- Make up to 3 attempts (Initial attempt + 2 retries)
local RETRY_PAUSE_CONSTANT = 1 -- Base wait time between attempts
local RETRY_PAUSE_EXPONENT_BASE = 2 -- Base number raised to the power of the retry number for exponential backoff

local function functionThatMightError(someParameter)
	if math.random(2) == 1 then
		print("Erroring")
		error("Custom ERROR message!")
	else
		print("Succeeding")
		return "Custom SUCCESS result!", someParameter
	end
end

while true do
	local attempts = 0
	local lastAttemptedAt = os.clock()

	local success, result, someParameter = retryAsync(function()
		attempts += 1

		local nowTime = os.clock()
		local timeSinceLastAttempt = math.round(nowTime - lastAttemptedAt)
		lastAttemptedAt = nowTime
		local secondsLaterString = if timeSinceLastAttempt > 0
			then string.format("(%d seconds later) ", timeSinceLastAttempt)
			else ""

		print(string.format("%sAttempt %d", secondsLaterString, attempts))
		return functionThatMightError("Some parameter")
	end, MAX_ATTEMPTS, RETRY_PAUSE_CONSTANT, RETRY_PAUSE_EXPONENT_BASE)

	local successString = if success then "Succeeded" else "Failed"
	local pluralString = if attempts > 1 then "s" else ""
	print(
		string.format(
			"\n%s after %d attempt%s!\nResult: '%s'\nsomeParameter: '%s'",
			successString,
			attempts,
			pluralString,
			result,
			tostring(someParameter)
		)
	)
	task.wait(5) -- Seconds between demos
	print("\nNEXT DEMO")
end
