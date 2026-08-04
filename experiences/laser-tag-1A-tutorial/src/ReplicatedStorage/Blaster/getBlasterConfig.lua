--!nocheck
--[[
	Gets the configuration of the player's blaster

	Configurations for each blaster type are stored in laserBlastersFolder.

	The player's 'blasterType' attribute will correspond to one blaster type (if set).
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local laserBlastersFolder = ReplicatedStorage.Instances.LaserBlastersFolder

local function getBlasterConfig(player: Player?): Configuration?
	if not player then
		player = Players.LocalPlayer
	end

	local blasterType = player:GetAttribute(PlayerAttribute.blasterType)
	if not blasterType then
		return nil
	end

	local blasterConfig = laserBlastersFolder:FindFirstChild(blasterType)
	assert(blasterConfig, `Missing configuration instance for blaster {blasterType}`)

	return blasterConfig
end

return getBlasterConfig
