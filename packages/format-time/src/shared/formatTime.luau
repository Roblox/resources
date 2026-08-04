--!strict

--[[
	Formats a number of seconds into a pretty string of Hours, Minutes, and Seconds.
	If all hours are 0, they are omitted.
	If all hours and all minutes are 0, they are both omitted.
	Leading 0's from hours are removed.
	If hours are omitted, leading 0's from minutes are removed.
	If hours and minutes are omitted, leading 0's from seconds are removed.

	Examples:

	local HOUR_1 = 60 * 60
	local HOUR_23 = 23 * HOUR_1
	local MINUTE_1 = 60
	local MINUTE_59 = 59 * MINUTE_1

	formatTime(HOUR_1 + 0 + 0) -- 1:00:00
	formatTime(HOUR_23 + MINUTE_59 + 59) -- 23:59:59
	formatTime(0 + MINUTE_59 + 59) -- 59:59
	formatTime(0 + MINUTE_1 + 0) -- 1:00
	formatTime(0 + 0 + 59) -- 59
	formatTime(0 + 0 + 1) -- 1
	formatTime(0 + 0 + 0) -- 0
--]]

local MAX_SUPPORTED_SECONDS = 86400 -- 24 hours

local function formatTime(seconds: number)
	local clampedSeconds = math.clamp(seconds, 0, MAX_SUPPORTED_SECONDS)

	if clampedSeconds ~= seconds then
		warn(
			string.format(
				"Seconds (%d) is outside supported range [0, %d]. Using (%d) instead.",
				seconds,
				MAX_SUPPORTED_SECONDS,
				clampedSeconds
			)
		)
	end

	local dateTime = DateTime.fromUnixTimestamp(clampedSeconds)
	local universalTime = dateTime:ToUniversalTime()

	local formattedTime
	if universalTime.Hour > 0 then
		formattedTime = dateTime:FormatUniversalTime("H:mm:ss", "zh-cn")
	elseif universalTime.Minute > 0 then
		formattedTime = dateTime:FormatUniversalTime("m:ss", "zh-cn")
	else
		formattedTime = dateTime:FormatUniversalTime("s", "zh-cn")
	end

	return formattedTime
end

return formatTime
