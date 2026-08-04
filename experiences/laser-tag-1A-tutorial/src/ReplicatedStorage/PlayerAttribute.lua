--[[
	Attribute names set on the player

	'blasterType' is the type of blaster the player has, should only be set on the Server.
	'blasterStateServer' is the state of the blaster on the Server.
	'blasterStateClient' is the state of the blaster on the Client.
	'playerState' is the state of the player, see PlayerState for possible states.
--]]

local PlayerAttribute = {
	blasterType = "blasterType",
	blasterStateServer = "blasterStateServer",
	blasterStateClient = "blasterStateClient",
	playerState = "playerState",
}

return PlayerAttribute
