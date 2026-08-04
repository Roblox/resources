--[[
	Ensures the ray path's destination is not beyond an obstruction of the map (e.g. a wall).
--]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RayResult = require(ReplicatedStorage.LaserRay.RayResult)
local BlastData = require(ReplicatedStorage.Blaster.BlastData)

local function isRayPathObstructed(rayResult: RayResult.Type, blastData: BlastData.Type): boolean
	-- Raycast to check for static map objects in the way; we only want to include static
	-- geometry so we don't get different results on the Client and Server
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { Workspace:FindFirstChild("World") }

	local scaledDirection = (rayResult.destination.Position - blastData.originCFrame.Position)

	-- Shorten the raycast by 1 stud to ignore any walls hit at the destination
	scaledDirection *= (scaledDirection.Magnitude - 1) / scaledDirection.Magnitude

	local result = Workspace:Raycast(blastData.originCFrame.Position, scaledDirection, raycastParams)

	-- If a result was hit, this means the result is an obstruction and the ray is not valid
	return result ~= nil
end

return isRayPathObstructed
