--!strict

--[[
	Function to call and retry a given function, up to maxAttempts times.
	This function waits pauseConstant + (pauseExponent ^ numAttempts) between retries for progressive exponential backoff.
	Calls are made with the functionCallHandler (default: pcall)
	and the results of this (in the form of success, errorMessage or ...) are returned.
--]]

type Function = (...any) -> ...any
export type FunctionHandler = (...any) -> (boolean, ...any)

local function retryAsync(
	func: Function,
	maxAttempts: number,
	optionalPauseConstant: number?,
	optionalPauseExponent: number?,
	optionalFunctionCallHandler: ((Function) -> (boolean, ...any))?
): (boolean, ...any)
	-- Using separate variables to satisfy the type checker
	local pauseConstant: number = optionalPauseConstant or 0
	local pauseExponent: number = optionalPauseExponent or 0
	local functionCallHandler: FunctionHandler = optionalFunctionCallHandler or pcall

	local attempts = 0
	local success: boolean, result: { any }

	while attempts < maxAttempts do
		attempts = attempts + 1

		local returnValues: { any }

		returnValues = { functionCallHandler(func) }

		success = table.remove(returnValues, 1) :: boolean
		result = returnValues

		if success then
			break
		end

		local pauseTime = pauseConstant + (pauseExponent ^ attempts)

		if attempts < maxAttempts then
			task.wait(pauseTime)
		end
	end

	if success then
		return success, table.unpack(result)
	else
		local errorMessage = not success and result[1] :: any or nil
		return success, errorMessage :: any
	end
end

return retryAsync
