local Players = game:GetService("Players")

local function getPlayerFromPart(part: BasePart): Player?
	local character = part.Parent
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

return getPlayerFromPart
