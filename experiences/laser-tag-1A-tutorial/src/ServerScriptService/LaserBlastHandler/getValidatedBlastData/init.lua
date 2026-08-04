--[[
	Returns nil if the data was unable to be validated, otherwise a table of validated BlastData.

	Since the blastData table came from the Client, we can't trust it because exploiters can
	modify data sent to the Server. So, we reconstruct what we can with known true data,
	and copy the rest. This filters the table to contain expected data and validates that data
	as best we can.

	Validations include:
		- BlastData contents are of the expected type
		- Player has a blaster
		- Player's character exists
		- There is a reasonable distance between the origin of a blast and the player's character
		- RayResults (see getValidatedRayResults)

	See ToleranceValues for the values used to determine if values are reasonable.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BlastData = require(ReplicatedStorage.Blaster.BlastData)
local ToleranceValues = require(ServerStorage.ToleranceValues)
local getBlasterConfig = require(ReplicatedStorage.Blaster.getBlasterConfig)

local validateBlastData = require(script.validateBlastData)
local getValidatedRayResults = require(script.getValidatedRayResults)

local function getValidatedBlastData(player: Player, blastData: BlastData.Type): BlastData.Type?
	-- Check value types we're copying over are of the expected type
	local isValidBlastData = validateBlastData(blastData)
	if not isValidBlastData then
		warn(`Player {player.Name} sent an invalid blast data {blastData}`)
		return
	end

	local blasterConfig = getBlasterConfig(player)
	if not blasterConfig then
		warn(`Player {player.Name} blasted without a blaster equipped`)
		return
	end

	-- The Client sends origin as the camera position but we're using character position,
	-- so we expect there will always be some offset.
	-- Also, there is network delay between when the Client sends the blast signal
	-- and when the Server receives it, so the character may have moved since the blast.
	-- For this reason, we include some tolerance in our distance sanity check.
	local rootPartCFrame = player.Character and player.Character:GetPivot()
	if not rootPartCFrame then
		warn(`Player {player.Name} blasted without a character`)
		return
	end

	local distanceFromCharacterToOrigin = blastData.originCFrame.Position - rootPartCFrame.Position
	if distanceFromCharacterToOrigin.Magnitude > ToleranceValues.DISTANCE_SANITY_CHECK_TOLERANCE_STUDS then
		warn(`Player {player.Name} failed an origin sanity check while blasting`)
		return
	end

	-- Validate ray results
	local validatedRayResults = getValidatedRayResults(player, blastData)

	-- Construct a validated property table. Creating a new table instead of re-using the one from the Client
	-- ensures that there is no extra information, e.g. this filters out extra table entries if an exploiter added them in
	local validatedBlastData: BlastData.Type = {
		player = player,
		originCFrame = blastData.originCFrame,
		rayResults = validatedRayResults,
	}

	return validatedBlastData
end

return getValidatedBlastData
