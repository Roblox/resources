-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function getPitchAndYaw(lookVector: Vector3): (number, number)
	local pitch = math.asin(lookVector.Y)
	local yaw = math.atan2(lookVector.Z, -lookVector.X) + math.pi / 2

	return pitch, yaw
end

return getPitchAndYaw
