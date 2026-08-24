-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local getDistances = require(script.Parent.getDistances)
local getInstancesInArc = require(script.Parent.getInstancesInArc)
local getInstancesInRadius = require(script.Parent.getInstancesInRadius)
local hasLineOfSight = require(script.Parent.hasLineOfSight)

local function getClosestVisibleInstances(
	instances: { PVInstance },
	origin: CFrame,
	length: number,
	angle: number?,
	count: number,
	raycastParams: RaycastParams
): { PVInstance }
	if #instances == 0 or length <= 0 or count <= 0 then
		return {}
	end
	assert(not angle or (angle >= 0 and angle <= 2 * math.pi), "Angle must be in the range [0, 2π]")

	local inRadius = getInstancesInRadius(instances, origin.Position, length)
	if #inRadius == 0 then
		return {}
	end

	local inArc = getInstancesInArc(inRadius, origin, length, angle)
	if #inArc == 0 then
		return {}
	end

	local distances = getDistances(inArc, origin.Position)
	table.sort(inArc, function(a, b)
		return distances[a] < distances[b]
	end)

	local result = table.create(math.min(count, #inArc)) :: { PVInstance }

	-- inArc is sorted by distance, so we can quit early once we have enough results.
	for _, instance in inArc do
		if hasLineOfSight(origin.Position, instance, raycastParams) then
			table.insert(result, instance)
		end

		-- Quit early once we have enough results.
		if #result >= count then
			break
		end
	end

	return result
end

return getClosestVisibleInstances
