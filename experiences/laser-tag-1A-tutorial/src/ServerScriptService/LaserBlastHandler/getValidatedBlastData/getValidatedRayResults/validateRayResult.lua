--[[
	Validates the types within a RayResult object.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RayResult = require(ReplicatedStorage.LaserRay.RayResult)

local function validateRayResult(rayResult: RayResult.Type): boolean
	if typeof(rayResult) ~= "table" then
		return false
	elseif typeof(rayResult.destination) ~= "CFrame" then
		return false
	elseif -- Verify taggedPlayer is either nil, or an Instance of class Player
		not (
			rayResult.taggedPlayer == nil
			or (typeof(rayResult.taggedPlayer) == "Instance" and rayResult.taggedPlayer:IsA("Player"))
		)
	then
		return false
	end

	return true
end

return validateRayResult
