--[[
	Possible states for a player to be in.

	Primarily used in PlayerStateHandler (Client and Server) to adapt the blaster state or
	player controls based on the state of the player.
--]]

local PlayerState = {
	SelectingBlaster = "SelectingBlaster",
	Playing = "Playing",
	TaggedOut = "TaggedOut",
}

return PlayerState
