--[[
	Performs a number of raycasts from an origin toward a direction, returning an array of RayResults
	containing the destination of the ray as well as a tagged player if hit.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RayResult = require(ReplicatedStorage.LaserRay.RayResult)
local getPlayerFromDescendant = require(script.getPlayerFromDescendant)

local MAX_DISTANCE = 500

local function castLaserRay(player: Player, origin: Vector3, rayDirections: { Vector3 }): { RayResult.Type }
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character }

	local rayResults = {}

	for _, rayDirection in rayDirections do
		local result = Workspace:Raycast(origin, rayDirection * MAX_DISTANCE, raycastParams)
		local destination, taggedPlayer

		if result then
			destination = CFrame.new(result.Position, result.Position + result.Normal)
			taggedPlayer = getPlayerFromDescendant(result.Instance)
		else
			-- If the raycast did not hit an instance, calculate the endpoint of the ray as the destination.
			-- 'taggedPlayer' can be set to nil as no instance hit means no player was tagged.
			local distantPosition = origin + rayDirection * MAX_DISTANCE
			destination = CFrame.lookAt(distantPosition, distantPosition - rayDirection)
			taggedPlayer = nil
		end
		table.insert(rayResults, {
			destination = destination,
			taggedPlayer = taggedPlayer,
		})
	end

	return rayResults
end

return castLaserRay
