-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function getInstancesInRadius(
	instances: { PVInstance },
	center: Vector3,
	maxDistance: number,
	minDistance: number?
): { PVInstance }
	if #instances == 0 or maxDistance <= 0 or (minDistance and minDistance > maxDistance) then
		return {}
	end

	minDistance = minDistance or 0
	local result = {}

	for _, instance in instances do
		local position = instance:GetPivot().Position
		local distance = (position - center).Magnitude

		if distance >= minDistance and distance <= maxDistance then
			table.insert(result, instance)
		end
	end

	return result
end

return getInstancesInRadius
