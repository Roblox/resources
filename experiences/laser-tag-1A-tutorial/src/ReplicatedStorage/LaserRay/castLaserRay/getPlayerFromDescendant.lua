--[[
	Returns the Player associated with a Character if the given part is a descendant of the Character,
	otherwise returns nil

	Used by both Client and Server in castLaserRay to get which player was tagged from the RaycastResult
--]]

local Players = game:GetService("Players")

local function getPlayerFromDescendant(part: BasePart): Player?
	local player
	local checkInstance = part

	while checkInstance and not player do
		-- The model checked here would be the player's Character
		checkInstance = checkInstance:FindFirstAncestorWhichIsA("Model")
		player = Players:GetPlayerFromCharacter(checkInstance)
	end

	return player
end

return getPlayerFromDescendant
