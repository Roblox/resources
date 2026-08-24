-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)

local function hasLineOfSight(
	viewerPosition: Vector3,
	target: PVInstance,
	raycastParams: RaycastParams,
	range: number?
): boolean
	local direction = target:GetPivot().Position - viewerPosition
	local distance = direction.Magnitude

	if distance == 0 then
		return true
	end

	if range and distance > range then
		return false
	end

	local raycastResult = Workspace:Raycast(
		viewerPosition,
		direction.Unit * (distance + Constants.LINE_OF_SIGHT_RAYCAST_EXTRA_DISTANCE),
		raycastParams
	)

	if not raycastResult then
		return false
	end

	local hitInstance = raycastResult.Instance

	return hitInstance == target or hitInstance:IsDescendantOf(target)
end

return hasLineOfSight
