-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Constants = require(script.Parent.Constants)
local getXZDistance = require(script.Parent.getXZDistance)

local function isWithinXZDistance(instance: PVInstance, target: Vector3, stoppingDistance: number?): boolean
	local xzDistance = getXZDistance(instance, target)
	local threshold = math.max(stoppingDistance or 0, Constants.DEFAULT_NORMAL_DISTANCE_MAXIMUM)
	return xzDistance <= threshold
end

return isWithinXZDistance
