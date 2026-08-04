--[[
	Validates that a laser's angle from the origin of the blast is correct; solves for the angle of the laser in the spread using
	'lasersPerBlast' and 'laserSpreadDegrees', and compares this with the claimed angle from the blast origin.

	Without this, an exploiter could say all their lasers in a multi blast ended at the same point, all hitting a player for example.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RayResult = require(ReplicatedStorage.LaserRay.RayResult)
local ToleranceValues = require(ServerStorage.ToleranceValues)

local getAngleBetweenDirections = require(script.getAngleBetweenDirections)

local function isRayAngleFromOriginValid(
	originCFrame: CFrame,
	rayResult: RayResult.Type,
	expectedDirection: Vector3
): boolean
	-- Compare the angle from the Client with the expected angle
	local claimedDirection = (rayResult.destination.Position - originCFrame.Position).Unit
	local directionErrorDegrees = getAngleBetweenDirections(claimedDirection, expectedDirection)

	-- Return whether the difference between these angles is above the tolerance value
	return directionErrorDegrees <= ToleranceValues.BLAST_ANGLE_SANITY_CHECK_TOLERANCE_DEGREES
end

return isRayAngleFromOriginValid
