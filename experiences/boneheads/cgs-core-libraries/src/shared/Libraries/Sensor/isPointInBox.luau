-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function isPointInBox(point: Vector3, origin: CFrame, size: Vector3): boolean
	if size.X < 0 or size.Y < 0 or size.Z < 0 then
		return false
	end

	local halfSize = size * 0.5
	local relativePosition = origin:PointToObjectSpace(point):Abs()

	return relativePosition:Min(halfSize) == relativePosition
end

return isPointInBox
