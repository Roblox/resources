--!strict
-- The passage of time, and the decision to rain.
--
-- Real seconds convert to game hours through SECONDS_PER_GAME_HOUR, and the
-- same clock drives Lighting.ClockTime so the sky agrees with the schedule.
--
-- Rain is impossible before MIN_TIME_BETWEEN_RAIN_HOURS and certain by
-- MAX_TIME_BETWEEN_RAIN_HOURS, with the odds climbing in between.

local Lighting = game:GetService("Lighting")

local WeatherSystemConfig = require(script.Parent.WeatherSystemConfig)

local WeatherClock = {}

-- Write at a fixed rate rather than every frame.
local WRITE_HZ = 15

local elapsedHours = 0
local hoursSinceRain = 0
local clockWriteCountdown = 0

local function writeInterval(): number
	return 1 / WRITE_HZ
end

function WeatherClock.reset()
	elapsedHours = 0
	hoursSinceRain = 0
	clockWriteCountdown = 0
	if WeatherSystemConfig.DRIVE_LIGHTING_CLOCK then
		Lighting.ClockTime = WeatherSystemConfig.STARTING_CLOCK_TIME % 24
	end
end

-- Advance time and report how many game hours passed.
function WeatherClock.step(deltaSeconds: number): number
	local secondsPerHour = math.max(WeatherSystemConfig.SECONDS_PER_GAME_HOUR, 0.001)
	local deltaHours = deltaSeconds / secondsPerHour
	elapsedHours += deltaHours

	if WeatherSystemConfig.DRIVE_LIGHTING_CLOCK then
		-- ClockTime is replicated and makes clients recompute the sky, so step
		-- it at the sky update rate rather than every frame.
		clockWriteCountdown -= deltaSeconds
		if clockWriteCountdown <= 0 then
			clockWriteCountdown = writeInterval()
			Lighting.ClockTime = (WeatherSystemConfig.STARTING_CLOCK_TIME + elapsedHours) % 24
		end
	end

	return deltaHours
end

-- Roll for the start of a storm, accumulating the dry spell as a side effect.
function WeatherClock.shouldStartRain(deltaHours: number): boolean
	local minGap = WeatherSystemConfig.MIN_TIME_BETWEEN_RAIN_HOURS
	local maxGap = WeatherSystemConfig.MAX_TIME_BETWEEN_RAIN_HOURS

	local previousHours = hoursSinceRain
	hoursSinceRain += deltaHours

	if hoursSinceRain < minGap then
		return false
	end

	local span = maxGap - minGap
	if span <= 0 then
		return true
	end

	-- This is a hazard rate, not the flat odds you might expect. Comparing
	-- `math.random() < progress` each frame would fire almost immediately,
	-- because even long odds land quickly given sixty attempts a second.
	-- Dividing this step's share of the window by the probability mass still
	-- unspent spreads the start evenly across the whole window instead, and
	-- drives the chance to 1 exactly as the window closes.
	local spent = math.clamp((previousHours - minGap) / span, 0, 1)
	local stepShare = math.clamp(deltaHours / span, 0, 1)
	local chance = stepShare / math.max(1 - spent, 1e-6)

	return math.random() < chance
end

function WeatherClock.onRainEnded()
	hoursSinceRain = 0
end

-- Total length of a storm, transitions included.
function WeatherClock.rollStormDurationHours(): number
	local minHours = WeatherSystemConfig.MIN_RAIN_DURATION_HOURS
	local maxHours = WeatherSystemConfig.MAX_RAIN_DURATION_HOURS
	local duration = minHours + math.random() * (maxHours - minHours)

	-- Both ramps have to fit inside the storm or they would overlap.
	return math.max(duration, WeatherSystemConfig.RAIN_TRANSITION_HOURS * 2)
end

function WeatherClock.getHoursSinceRain(): number
	return hoursSinceRain
end

function WeatherClock.getElapsedHours(): number
	return elapsedHours
end

return WeatherClock
