--!strict

--[[
	Returns the magnitude in studs of the distance between a player's character primary part
	and a Vector3 point

	Differs from Player:DistanceFromCharacter() by returning 'nil' if the character doesn't exist,
	rather than an often undesired result of 0.
--]]

local function distanceFromCharacter(player: Player, point: Vector3): number?
	if not (player.Character and player.Character.PrimaryPart) then
		return nil
	end

	local character = player.Character :: Model
	local primaryPart = character.PrimaryPart :: BasePart

	local distance = (primaryPart.Position - point).Magnitude
	return distance
end

return distanceFromCharacter
