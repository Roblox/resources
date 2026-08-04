--!strict

--[[
	Takes an arbitrary number of callback, and executes them in parallel, returning the results of the first to return.
	If an error is thrown, that error is bubbled up to the main thread.
	When the first callback returns, the rest are cancelled using task.cancel.

	Exposes similar functionality that Promise.race provides for promises, but for asynchronous lua callbacks
--]]

type Callback = () -> ...any

local function waitForFirstAsync(...: Callback)
	local thisThread = coroutine.running()
	local resumed = false
	local errorThrown: any

	local function resume(...: any)
		if resumed then
			return
		end
		resumed = true

		task.spawn(thisThread, ...)
	end

	for _, callback in ipairs({ ... }) do
		task.defer(function()
			-- We are capturing all values returned by pcall into a table so we can resume this thread
			-- with all values if multiple are returned
			local pcallReturnValues = { pcall(callback) }
			if not pcallReturnValues[1] then
				errorThrown = pcallReturnValues[2]
			end

			resume(table.unpack(pcallReturnValues, 2))
		end)
	end

	local returnValues = { coroutine.yield() }

	if errorThrown then
		-- Return the stack trace three callers up to where the function passed into waitForFirstAsync was
		-- declared
		error(errorThrown, 3)
	end

	return table.unpack(returnValues)
end

return waitForFirstAsync
