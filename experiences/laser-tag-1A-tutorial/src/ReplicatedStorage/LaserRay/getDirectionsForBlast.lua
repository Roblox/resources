--[[
	Determines the directions of each laser within a blast based on an origin CFrame.

	The lasers in the blast are evenly spread horizontally relative to the origin CFrame's
	direction. The width of the spread is determined by the blaster configuration's "laserSpreadDegrees",
	and the number of directions returned is determined by the blaster configuration's "lasersPerBlast".
--]]

local function getDirectionsForBlast(originCFrame: CFrame, blasterConfig: Configuration): { Vector3 }
	local directions = {}

	local numLasers = blasterConfig:GetAttribute("lasersPerBlast")
	local laserSpreadDegrees = blasterConfig:GetAttribute("laserSpreadDegrees")

	if numLasers == 1 then
		-- For single lasers, they aim straight
		table.insert(directions, originCFrame.LookVector)
	elseif numLasers > 1 then
		-- For multiple lasers, we spread them out evenly horizontally
		-- over an interval laserSpreadDegrees around the center
		local leftAngleBound = laserSpreadDegrees / 2
		local rightAngleBound = -leftAngleBound
		local degreeInterval = laserSpreadDegrees / (numLasers - 1)

		for angle = rightAngleBound, leftAngleBound, degreeInterval do
			local direction = (originCFrame * CFrame.Angles(0, math.rad(angle), 0)).LookVector
			table.insert(directions, direction)
		end
	end

	return directions
end

return getDirectionsForBlast
