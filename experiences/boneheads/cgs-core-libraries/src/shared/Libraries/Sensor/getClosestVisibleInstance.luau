-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local getDistances = require(script.Parent.getDistances)
local getInstancesInArc = require(script.Parent.getInstancesInArc)
local getInstancesInRadius = require(script.Parent.getInstancesInRadius)
local hasLineOfSight = require(script.Parent.hasLineOfSight)

local function getClosestVisibleInstance(
	instances: { PVInstance },
	origin: CFrame,
	length: number,
	angle: number?,
	raycastParams: RaycastParams
): PVInstance?
	if #instances == 0 or length <= 0 then
		return nil
	end
	assert(not angle or (angle >= 0 and angle <= 2 * math.pi), "Angle must be in the range [0, 2π]")

	local inRadius = getInstancesInRadius(instances, origin.Position, length)
	if #inRadius == 0 then
		return nil
	end

	local inArc = getInstancesInArc(inRadius, origin, length, angle)
	if #inArc == 0 then
		return nil
	end

	local distances = getDistances(inArc, origin.Position)
	table.sort(inArc, function(a, b)
		return distances[a] < distances[b]
	end)

	for _, instance in inArc do
		if hasLineOfSight(origin.Position, instance, raycastParams) then
			return instance
		end
	end

	return nil
end

return getClosestVisibleInstance
