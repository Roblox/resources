--!strict

--[[
	Calls a given callback on some specified interval until the
	clear function is called.

	The callback is given deltaTime since the last call completed, along
	with any extra parameters passed to setSequentialInterval.

	The first callback call is made after intervalSeconds passes,
	i.e. it is not immediate.
--]]

local function setSequentialInterval(callback: (number, ...any) -> nil, intervalSeconds: number, ...: any)
	local cleared = false

	local function call(scheduledTime: number, ...: any)
		if cleared then
			return
		end

		local deltaTime = os.clock() - scheduledTime

		callback(deltaTime, ...)

		task.delay(intervalSeconds, call, os.clock(), ...)
	end

	local function clear()
		cleared = true
	end

	task.delay(intervalSeconds, call, os.clock(), ...)

	return clear
end

return setSequentialInterval
