--[[
	Validates the RayResults sent from the Client

	Validations include:
		- Each RayResult is of the expected type
		- The angle of each laser in the blast is expected relative to the blast origin
		- If a player is tagged, the tagged player is within a reasonable distance of the blast destination
		- The ray path's destination is not beyond an obstruction of the map (e.g. a wall)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RayResult = require(ReplicatedStorage.LaserRay.RayResult)
local BlastData = require(ReplicatedStorage.Blaster.BlastData)

local getBlasterConfig = require(ReplicatedStorage.Blaster.getBlasterConfig)
local getDirectionsForBlast = require(ReplicatedStorage.LaserRay.getDirectionsForBlast)
local validateRayResult = require(script.validateRayResult)
local isRayAngleFromOriginValid = require(script.isRayAngleFromOriginValid)
local isPlayerNearPosition = require(script.isPlayerNearPosition)
local isRayPathObstructed = require(script.isRayPathObstructed)

local function getValidatedRayResults(player: Player, blastData: BlastData.Type): { RayResult.Type }
	local validatedRayResults = {}

	local blasterConfig = getBlasterConfig(player)
	local expectedRayDirections = getDirectionsForBlast(blastData.originCFrame, blasterConfig)

	for index, rayResult in blastData.rayResults do
		-- Check value types we're copying over are of the expected type
		local isValidRayResult = validateRayResult(rayResult)
		if not isValidRayResult then
			warn(`Player {player.Name} sent an invalid ray {rayResult}`)
		end

		-- Validate the ray's angle from the blast origin
		local isValidAngle =
			isRayAngleFromOriginValid(blastData.originCFrame, blastData.rayResults[index], expectedRayDirections[index])
		if not isValidAngle then
			warn(`Player {player.Name} claimed a blast ray had an invalid angle from the origin`)
			-- Skips inserting this ray into our validated results table
			continue
		end

		-- Validate tagged player is near ray destination hit
		if rayResult.taggedPlayer then
			local isPlayerNearby = isPlayerNearPosition(rayResult.taggedPlayer, rayResult.destination.Position)
			if not isPlayerNearby then
				warn(
					`Player {player.Name} claimed they tagged player {rayResult.taggedPlayer.Name} who is not nearby the destination`
				)
				rayResult.taggedPlayer = nil
			end
		end

		local isObstructed = isRayPathObstructed(rayResult, blastData)
		if isObstructed then
			warn(`Player {player.Name} claimed a blast ray went through a static part of the map`)
			-- Skips inserting this ray into our validated results table
			continue
		end

		table.insert(validatedRayResults, {
			destination = rayResult.destination,
			taggedPlayer = rayResult.taggedPlayer,
		})
	end

	return validatedRayResults
end

return getValidatedRayResults
