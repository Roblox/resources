-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local getDistance = require(script.Parent.getDistance)
local function getDistances(instances: { PVInstance }, position: Vector3): { [PVInstance]: number }
	if #instances == 0 then
		return {}
	end

	local distances = {}
	for _, instance in instances do
		distances[instance] = getDistance(instance, position)
	end
	return distances
end

return getDistances
