-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function getDistance(instance: PVInstance, position: Vector3): number
	return (instance:GetPivot().Position - position).Magnitude
end

return getDistance
