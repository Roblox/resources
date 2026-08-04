--!strict

--[[
	Utility for formatting time, from seconds, into a human-readable string in the format.

	Parameters can be used to specify:
		- maxUnitCount: The maximum number of time units to include in the formatted string, starting from the largest unit, e.g. days & hours is 2 units
		- includePadding: Whether to append space padding at the end of the string to ensure consistent string length based on the units present
		- suffix: The suffix to append to the end of the formatted string. If padding is enabled, the suffix will be appended before the extra spaces.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TranslationStrings = require(ReplicatedStorage.FeaturePackagesCore.Configs.TranslationStrings)

local SECONDS_IN_MINUTE = 60
local SECONDS_IN_HOUR = 3600
local SECONDS_IN_DAY = 86400

local function formatTime(t: number, maxUnitCount: number?, includePadding: boolean?, suffix: string?): string
	-- Max character count is calculated from the combination of unit strings present in the final time string
	local maxCharacterCount = 0
	local unitCount = 0
	local timeStrings = {}
	maxUnitCount = maxUnitCount or 4

	-- Nil check for maxUnitCheck is unnecessary, but included so that the type checker knows it is not nil after this point
	assert(
		maxUnitCount and maxUnitCount >= 1 and maxUnitCount <= 4,
		`Max units must be within [1, 4], got {maxUnitCount}`
	)

	local orderedUnitData = {
		{
			formatString = TranslationStrings.TIME_FORMAT_DAYS,
			value = t // SECONDS_IN_DAY,
		},
		{
			formatString = TranslationStrings.TIME_FORMAT_HOURS,
			value = (t % SECONDS_IN_DAY) // SECONDS_IN_HOUR,
		},
		{
			formatString = TranslationStrings.TIME_FORMAT_MINUTES,
			value = (t % SECONDS_IN_HOUR) // SECONDS_IN_MINUTE,
		},
		{
			formatString = TranslationStrings.TIME_FORMAT_SECONDS,
			value = (t % SECONDS_IN_MINUTE) // 1,
		},
	}

	for _, unit in ipairs(orderedUnitData) do
		if unit.value > 0 and unitCount < maxUnitCount :: number then
			unitCount += 1
			maxCharacterCount += #unit.formatString
			local unitString = string.gsub(unit.formatString, "00", tostring(unit.value))
			table.insert(timeStrings, unitString)
		end
	end

	if suffix then
		table.insert(timeStrings, suffix)
		maxCharacterCount += #suffix
	end

	local timeString = table.concat(timeStrings, " ")
	maxCharacterCount += #timeStrings - 1 -- Add the spaces between each unit string

	-- If padding is enabled, add extra spaces to the end of the string to ensure a consistent length
	if includePadding then
		timeString ..= string.rep(" ", maxCharacterCount - #timeString)
	end

	return timeString
end

return formatTime
