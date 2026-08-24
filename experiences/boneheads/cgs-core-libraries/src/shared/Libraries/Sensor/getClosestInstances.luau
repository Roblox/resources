-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local getDistances = require(script.Parent.getDistances)

local function getClosestInstances(
	instances: { PVInstance },
	position: Vector3,
	count: number,
	maxDistance: number?
): { PVInstance }
	if #instances == 0 or count <= 0 then
		return {}
	end

	local distances = getDistances(instances, position)

	local sorted = table.clone(instances)
	table.sort(sorted, function(a, b)
		return distances[a] < distances[b]
	end)

	if maxDistance then
		local maxIndex = #sorted
		for i, instance in sorted do
			if distances[instance] > maxDistance then
				maxIndex = i - 1
				break
			end
		end

		count = math.min(count, maxIndex)
	end

	local result = {}
	table.move(sorted, 1, math.min(count, #sorted), 1, result)

	return result
end

return getClosestInstances
