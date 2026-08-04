--[[
	Possible states for a laser blaster to be in.

	The state of a player's blaster is tracked per player using attributes.
	'blasterStateServer' attribute on the Server.
	'blasterStateClient' attribute on the Client.
	This makes the state of a player's blaster accessible as long as the player is known.

	The Client tracks the blaster state to ensure the blaster's behavior is responsive when
	transitioning between states. The Server tracks the blaster state to verify whether or
	not the claimed Client state is valid when a blast is received. This is important because
	players can tamper with their blaster state on their Client, but not the Server.

	For example, if a player attempts to overwrite blasterStateClient to Ready to blast when
	it shouldn't, the Server will check blasterStateServer, see that this state is not Ready
	and reject their attempt to blast. The blast still occurs on the player's Client, but the
	Server validation prevents this blast from tagging any players or replicating the visuals
	to other players.
--]]

local BlasterState = {
	Ready = "Ready",
	Blasting = "Blasting",
	Disabled = "Disabled",
}

return BlasterState
