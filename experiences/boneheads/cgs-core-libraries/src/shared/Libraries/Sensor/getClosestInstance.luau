-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local getDistances = require(script.Parent.getDistances)

local function getClosestInstance(instances: { PVInstance }, position: Vector3): PVInstance
	assert(#instances > 0, "No instances provided")

	local distances = getDistances(instances, position)
	local minimum = distances[instances[1]]
	local closestInstance = instances[1]

	for instance, distance in distances do
		if distance < minimum then
			minimum = distance
			closestInstance = instance
		end
	end

	return closestInstance
end

return getClosestInstance
