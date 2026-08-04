--[[
	Given two directions, returns the angle between them.
--]]

local function getAngleBetweenDirections(directionA: Vector3, directionB: Vector3)
	local dotProduct = directionA:Dot(directionB)
	local cosAngle = math.clamp(dotProduct, -1, 1)
	local angle = math.acos(cosAngle)
	return math.deg(angle)
end

return getAngleBetweenDirections
