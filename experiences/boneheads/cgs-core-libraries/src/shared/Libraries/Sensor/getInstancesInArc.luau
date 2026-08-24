-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function getInstancesInArc(
	instances: { PVInstance },
	origin: CFrame,
	length: number,
	angle: number?
): { PVInstance }
	if #instances == 0 or length <= 0 then
		return {}
	end
	assert(not angle or (angle >= 0 and angle <= 2 * math.pi), "Angle must be in the range [0, 2π]")

	local result = {}
	local position = origin.Position
	local direction = origin.LookVector

	if not angle then
		for _, instance in instances do
			local distance = (instance:GetPivot().Position - position).Magnitude
			if distance <= length then
				table.insert(result, instance)
			end
		end

		return result
	end

	local minDotProduct = math.cos(angle / 2)

	for _, instance in instances do
		local instanceDirection = (instance:GetPivot().Position - position)
		local distance = instanceDirection.Magnitude

		if distance > length then
			continue
		end

		local dotProduct = direction:Dot(instanceDirection.Unit)
		if dotProduct >= minDotProduct then
			table.insert(result, instance)
		end
	end

	return result
end

return getInstancesInArc
