--[[
	Determines if a tagged player is within a reasonable distance of some position (blast destination).
--]]

local ServerStorage = game:GetService("ServerStorage")

local ToleranceValues = require(ServerStorage.ToleranceValues)

local function isPlayerNearPosition(player: Player, position: Vector3): boolean
	local character = player.Character
	if not character then
		return false
	end

	local distanceFromCharacterToPosition = position - character:GetPivot().Position
	if distanceFromCharacterToPosition.Magnitude > ToleranceValues.DISTANCE_SANITY_CHECK_TOLERANCE_STUDS then
		return false
	end

	return true
end

return isPlayerNearPosition
