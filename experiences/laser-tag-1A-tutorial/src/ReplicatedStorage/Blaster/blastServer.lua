--[[
	Used for blast related logic on the Server. Always check canPlayerBlast before calling.
	Sets the blaster state to "Blasting" until secondsBetweenBlasts has transpired.

	Used to track the state of the blaster on the Server to validate if the player can blast.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local BlasterState = require(ReplicatedStorage.Blaster.BlasterState)
local getBlasterConfig = require(ReplicatedStorage.Blaster.getBlasterConfig)

local function blastServer(player: Player)
	-- Disable starting another blast by setting the state to Blasting
	player:SetAttribute(PlayerAttribute.blasterStateServer, BlasterState.Blasting)

	local blasterConfig = getBlasterConfig(player)
	local secondsBetweenBlasts = blasterConfig:GetAttribute("secondsBetweenBlasts")

	-- Re-enable the blaster after secondsBetweenBlasts if the state is still 'Blasting'
	task.delay(secondsBetweenBlasts, function()
		local currentState = player:GetAttribute(PlayerAttribute.blasterStateServer)
		if currentState == BlasterState.Blasting then
			player:SetAttribute(PlayerAttribute.blasterStateServer, BlasterState.Ready)
		end
	end)
end

return blastServer
