--!strict
-- How far a rain particle falls in a given time, and how long it takes to fall
-- a given distance.
--
-- Without drag both would be one-liners, but drag is required to make rain
-- lean in the wind. Distance from time still has a closed form. Time from
-- distance does not, so that direction searches.

local WeatherSystemConfig = require(script.Parent.WeatherSystemConfig)

-- Avoid dividing by zero if drag is set to zero. Small enough that the math
-- stays accurate.
local MINIMUM_DRAG = 1e-5

local RainBallistics = {}

function RainBallistics.fallDistance(seconds: number): number
	local speed = math.max(WeatherSystemConfig.RAIN_EMITTER_SPEED, 0)
	local drag = math.max(WeatherSystemConfig.RAIN_EMITTER_DRAG, MINIMUM_DRAG)
	local terminal = math.abs(WeatherSystemConfig.RAIN_EMITTER_ACCELERATION.Y) / drag
	return terminal * seconds + (speed - terminal) * (1 - math.exp(-drag * seconds)) / drag
end

function RainBallistics.fallSeconds(distance: number): number
	-- A drop never needs to outlive one falling from the open sky, so that is
	-- both the answer for anything at ground level and the ceiling on the
	-- search below.
	local ceiling = WeatherSystemConfig.RAIN_EMITTER_LIFETIME_SECONDS
	if RainBallistics.fallDistance(ceiling) < distance then
		return ceiling
	end

	-- Binary search the curve above. fallDistance() only ever rises, so exactly
	-- one time hits the target and every pass can discard the half that cannot
	-- hold it. low always falls short and high always reaches, so returning high
	-- errs towards the drop landing rather than stopping short of the ground. 16
	-- passes keeps us within a small margin of error and costs very little.
	local low, high = 0, ceiling
	for _ = 1, 16 do
		local middle = (low + high) / 2
		if RainBallistics.fallDistance(middle) < distance then
			low = middle
		else
			high = middle
		end
	end
	return high
end

return RainBallistics
