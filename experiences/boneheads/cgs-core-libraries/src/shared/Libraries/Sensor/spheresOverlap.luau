-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function spheresOverlap(center1: Vector3, radius1: number, center2: Vector3, radius2: number): boolean
	local distance = (center1 - center2).Magnitude
	return distance < radius1 + radius2
end

return spheresOverlap
