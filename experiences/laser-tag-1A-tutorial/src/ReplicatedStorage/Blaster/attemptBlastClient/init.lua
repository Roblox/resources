--[[
	Checks if the blaster is in a valid state before blasting on the Client.

	Called upon receiving input from the player to blast in UserInputHandler.connectBlastListenersAsync
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local blastClient = require(script.blastClient)
local canLocalPlayerBlast = require(ReplicatedStorage.Blaster.canLocalPlayerBlast)

local function attemptBlastClient()
	if not canLocalPlayerBlast() then
		return
	end

	blastClient()
end

return attemptBlastClient
