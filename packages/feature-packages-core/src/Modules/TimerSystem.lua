--!strict

--[[
	TimerSystem is a utility for tracking the status of timers, 
	as well as performing the relevant calculations and firing events when timers finish.

	This module is useful if you want to get completion events and full timer features.
	These Timers are designed to be stored in datastores or sent between clients and servers,
	as such callbacks must be re registered in these cases and events are fired once the timer has completed,
	but there is no guarentee that the event just finished if it was stored in datastores, it might have finished 
	a week ago and is only being loaded now.

	Timers should be modified using the methods here rather than directly to keep events firing correctly.

	Important Methods:
	- setCompletionHandler: Use this method to set the callback that will be called when a timer completes.
		If the timer completes multiple times, it will be called the first time only. Untracking a timer will cancel the callback.
	- suspend: Use this method to prepare a timer to be paused and stored. It will still work as a timer with no change unless untracked.
	- unsuspend: Use this method to restore a timer to the time it was suspended and previously saved at.
	- track: Use this method to track the completion of a previously untracked timer.
	- untrack: Use this method to stop tracking a tracked timer, and cancel any callbacks it has.

	To store a running timer in data stores:
	If the timer should not count while in datastore, call suspend on it. 
	Save the Timer's table in datastore, the timer can still be used as normal even if it was suspended. 

	To load a running timer from data stores:
	Load the Timer's table from datastore.
	If the timer should not time while in datastore, call unsuspend on it.

	Timers that are stopped are unaffected by suspend and unsuspend, only unsuspend modifies the state of the timer in an observable way.
--]]

export type UnixTimestamp = number
export type Seconds = number

export type Timer = {
	durationInSeconds: Seconds?,
	elapsedSeconds: Seconds?,
	startUtc: UnixTimestamp?,
	rate: number?,
}

export type TimerCallback = (Timer) -> ()

local TimerSystem = {}

local activeTimers: { [Timer]: thread? } = {}

local completionCallbacks: { [Timer]: TimerCallback? } = {}

-- Get the current time in seconds utc
function TimerSystem.now(): UnixTimestamp
	return DateTime.now().UnixTimestamp
end

-- Calculate the time since startTime multiplied by a rate, plus some additional number of seconds alreadyCounted
-- Handles all nil cases for both
local function calculateElapsedTime(
	startTime: UnixTimestamp? | DateTime?,
	alreadyCounted: Seconds?,
	rate: number?
): Seconds
	if startTime then
		local elapsed =
			os.difftime(TimerSystem.now(), if type(startTime) == "number" then startTime else startTime.UnixTimestamp)
		return elapsed * (rate or 1) + (alreadyCounted or 0)
	else
		return alreadyCounted or 0
	end
end

local function handleCallback(timer: Timer)
	if not timer.durationInSeconds then
		activeTimers[timer] = nil
		return
	end

	local remaining = TimerSystem.getRealSecondsRemaining(timer)

	if remaining > 0 then
		activeTimers[timer] = task.delay(remaining, function()
			handleCallback(timer)
		end)
		return
	end

	local callback = completionCallbacks[timer]

	-- Remove the callback after the timer completes.
	completionCallbacks[timer] = nil
	activeTimers[timer] = nil

	if callback then
		callback(timer)
	end
end

local function unscheduleCompletion(timer: Timer)
	local oldThread = activeTimers[timer]
	if oldThread then
		pcall(task.cancel, oldThread)
		activeTimers[timer] = nil
	end
end

local function scheduleCompletion(timer: Timer)
	local oldThread = activeTimers[timer]
	if oldThread then
		unscheduleCompletion(timer)
	end

	-- No callback set, if one is set this will be called again.
	if not completionCallbacks[timer] then
		return
	end

	-- Timer never ends so no callback.
	if not timer.durationInSeconds then
		return
	end

	local secondsRemaining = TimerSystem.getRealSecondsRemaining(timer) or 0

	activeTimers[timer] = task.delay(secondsRemaining, function()
		handleCallback(timer)
	end)
end

-- Set the handler to call when the timer ends.
-- The handler is called once when the timer is completed, then unregistered.
function TimerSystem.setCompletionHandler(timer: Timer?, callback: TimerCallback)
	if not timer then
		return
	end

	completionCallbacks[timer] = callback

	if not activeTimers[timer] then
		scheduleCompletion(timer)
	end
end

-- Check if a timer is finished.
function TimerSystem.isFinished(timer: Timer?): boolean
	if not timer then
		return false
	end

	return TimerSystem.getSecondsRemaining(timer) <= 0
end

-- Check if a timer is running.
function TimerSystem.isRunning(timer: Timer?): boolean
	if not timer then
		return false
	end

	-- If there's a start time, timer is running.
	if timer.startUtc then
		return true
	end

	return false
end

-- Start a timer if it is not started.
function TimerSystem.start(timer: Timer?)
	if not timer then
		return
	end

	-- Timer is already started.
	if timer.startUtc then
		return
	end

	timer.startUtc = TimerSystem.now()
	scheduleCompletion(timer)
end

-- Stop a timer if it is running.
function TimerSystem.stop(timer: Timer?)
	if not timer then
		return
	end

	-- Timer is already not running.
	if not timer.startUtc then
		return
	end

	timer.elapsedSeconds = calculateElapsedTime(timer.startUtc, timer.elapsedSeconds, timer.rate)
	timer.startUtc = nil
	unscheduleCompletion(timer)
end

-- Get the number of seconds elapsed for a timer.
function TimerSystem.getElapsedSeconds(timer: Timer?): Seconds
	if not timer then
		return 0
	end

	return calculateElapsedTime(timer.startUtc, timer.elapsedSeconds, timer.rate)
end

-- Set the number of seconds elapsed for a timer.
function TimerSystem.setElapsedSeconds(timer: Timer?, time: Seconds?)
	if not timer then
		return
	end

	timer.elapsedSeconds = time

	-- If the timer is running, move the last started time to now.
	if timer.startUtc then
		timer.startUtc = TimerSystem.now()
		scheduleCompletion(timer)
	end
end

-- Get the time in seconds utc that a timer will end at, accounting for the current rate.
function TimerSystem.getEndTime(timer: Timer?): UnixTimestamp?
	if not timer then
		return nil
	end

	-- If the timer has no duration.
	if not timer.durationInSeconds then
		return nil
	end

	-- If the timer is not running.
	if not timer.startUtc then
		return nil
	end

	local previousElapsedSeconds = calculateElapsedTime(timer.startUtc, timer.elapsedSeconds, timer.rate)

	local secondsRemaining = timer.durationInSeconds - previousElapsedSeconds

	local realSecondsRemaining = secondsRemaining / TimerSystem.getRate(timer)

	return TimerSystem.now() + realSecondsRemaining
end

-- Set the duration for a timer to be such that the timer ends
-- at the specified time if it is started now, removing any rate.
function TimerSystem.setEndTime(timer: Timer?, endTime: UnixTimestamp?)
	if not timer then
		return
	end

	local elapsedSeconds = calculateElapsedTime(timer.startUtc, timer.elapsedSeconds, timer.rate)

	-- Timer's rate will be reset, update the elapsed and start time appropriately.
	if timer.rate and timer.rate ~= 1 then
		timer.elapsedSeconds = elapsedSeconds
		timer.rate = nil

		-- Timer is started, so set it back to now
		if timer.startUtc then
			timer.startUtc = TimerSystem.now()
		end
	end

	-- nil end time, remove the duration from the timer.
	if not endTime then
		timer.durationInSeconds = nil
		unscheduleCompletion(timer)
		return
	end

	local secondsUntilEndTime = endTime - TimerSystem.now()

	-- Set duration to the time passed plus the number of seconds until the timer should end.
	timer.durationInSeconds = elapsedSeconds + secondsUntilEndTime

	scheduleCompletion(timer)
end

-- Get the duration of a timer in seconds.
function TimerSystem.getDuration(timer: Timer?): Seconds?
	if not timer then
		return
	end

	return timer.durationInSeconds
end

-- Set the duration of a timer in seconds.
function TimerSystem.setDuration(timer: Timer?, seconds: Seconds?)
	if not timer then
		return
	end

	timer.durationInSeconds = seconds

	scheduleCompletion(timer)
end

-- Get the number of seconds remaining on a timer.
function TimerSystem.getSecondsRemaining(timer: Timer?): Seconds?
	if not timer then
		return nil
	end

	-- Timer has no end time
	if not timer.durationInSeconds then
		return nil
	end

	return timer.durationInSeconds - calculateElapsedTime(timer.startUtc, timer.elapsedSeconds, timer.rate)
end

-- Get the number of seconds remaining on a timer accounting for rate.
function TimerSystem.getRealSecondsRemaining(timer: Timer?): Seconds?
	local timeRemaining = TimerSystem.getSecondsRemaining(timer)
	if not timeRemaining then
		return nil
	end

	local rate = TimerSystem.getRate(timer)

	return timeRemaining / rate
end

-- Set the number of seconds remaining on a timer, and remove any rate.
function TimerSystem.setSecondsRemaining(timer: Timer?, secondsRemaining: Seconds?)
	if not timer then
		return
	end

	local elapsedSeconds = calculateElapsedTime(timer.startUtc, timer.elapsedSeconds, timer.rate)

	-- Timer's rate will be reset, update the elapsed and start time appropriately.
	if timer.rate and timer.rate ~= 1 then
		timer.elapsedSeconds = elapsedSeconds
		timer.rate = nil

		-- Timer is started, so set it back to now
		if timer.startUtc then
			timer.startUtc = TimerSystem.now()
		end
	end

	-- nil seconds remaining, so clear the duration
	if not secondsRemaining then
		timer.durationInSeconds = nil
		unscheduleCompletion(timer)
		return
	end

	timer.durationInSeconds = elapsedSeconds + secondsRemaining

	scheduleCompletion(timer)
end

-- Update a timer such that if it is unsuspended, its time passed will be the same as now.
function TimerSystem.suspend(timer: Timer?)
	if not timer then
		return
	end

	if timer.startUtc then
		timer.elapsedSeconds = calculateElapsedTime(timer.startUtc, timer.elapsedSeconds, timer.rate)
		timer.startUtc = TimerSystem.now()
	end
end

-- Reset a timer's start time to now if it was started.
function TimerSystem.unsuspend(timer: Timer?)
	if not timer then
		return
	end

	if timer.startUtc then
		timer.startUtc = TimerSystem.now()
	end

	scheduleCompletion(timer)
end

-- Register a timer for events when it completes.
function TimerSystem.track(timer: Timer?)
	if not timer then
		return
	end

	scheduleCompletion(timer)
end

-- Unregister a timer for events when it completes.
function TimerSystem.untrack(timer: Timer?)
	if not timer then
		return
	end

	unscheduleCompletion(timer)
	completionCallbacks[timer] = nil
end

-- Get a timer's rate.
function TimerSystem.getRate(timer: Timer?): number
	if not timer then
		return 1
	end

	return timer.rate or 1
end

-- Set a timer's rate.
function TimerSystem.setRate(timer: Timer?, rate: number?)
	if not timer then
		return
	end

	if timer.startUtc then
		timer.elapsedSeconds = calculateElapsedTime(timer.startUtc, timer.elapsedSeconds, timer.rate)
		timer.startUtc = TimerSystem.now()
	end

	timer.rate = rate

	scheduleCompletion(timer)
end

-- Create a new timer with an optional duration, either started or not.
function TimerSystem.new(duration: Seconds?, started: boolean?): Timer
	local timer: Timer = {}

	if duration then
		timer.durationInSeconds = duration
	end

	if started then
		TimerSystem.start(timer)
	end

	return timer
end

-- Create a new started timer that ends at a specific time.
function TimerSystem.newEndsAt(time: UnixTimestamp): Timer
	local timer: Timer = {}

	TimerSystem.setEndTime(timer, time)
	TimerSystem.start(timer)

	return timer
end

return TimerSystem
