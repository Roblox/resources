--[[
	Checks if a player is able to blast their blaster on the Server.

	The blaster state is stored on the player's 'blasterStateServer' attribute.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local BlasterState = require(ReplicatedStorage.Blaster.BlasterState)

local function canPlayerBlast(player: Player): boolean
	return player:GetAttribute(PlayerAttribute.blasterStateServer) == BlasterState.Ready
end

return canPlayerBlast
