--!strict

--[[
	Returns a value with Out tween direction of an Exponential tween style
	that reverses at a specified midpoint. Alpha and return value are both 0 <= x <= 1,
	and midpoint is 0 < x < 1.
--]]

local EPSILON = 0.001

local function getExponentialTweenValueWithMidpoint(alpha: number, midpoint: number)
	-- To avoid division by zero, midpoint needs to be 0 < midpoint < 1. Its purpose
	-- is to be somewhere between the 0 and 1 bounds to provide a switching point from
	-- increasing to decreasing, so logically it shouldn't be at either boundary. For this reason,
	-- we define EPSILON to define how near the bounds it can be.
	midpoint = math.clamp(midpoint, EPSILON, 1 - EPSILON)
	alpha = math.clamp(alpha, 0, 1)

	local function increasing()
		return 1 - 2 ^ (-10 * alpha / midpoint)
	end

	local function decreasing()
		return 1 - 2 ^ (10 * (alpha - 1) / (1 - midpoint))
	end
	return if alpha <= midpoint then increasing() else decreasing()
end

return getExponentialTweenValueWithMidpoint
