-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function getXZDistance(instance: PVInstance, target: Vector3): number
	local normalMask = Vector3.new(1, 0, 1)
	return ((instance:GetPivot().Position - target) * normalMask).Magnitude
end

return getXZDistance
