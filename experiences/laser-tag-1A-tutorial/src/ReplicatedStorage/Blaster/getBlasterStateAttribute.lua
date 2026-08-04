--[[
	Gets the correct attribute name for the blaster state based on the run context.
	Ensures the correct name is used in modules that share code within Client and Server.

	Used in scheduleDestroyForceField to listen to the correct blaster state.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)

local function getBlasterStateAttribute()
	if RunService:IsServer() then
		return PlayerAttribute.blasterStateServer
	end

	return PlayerAttribute.blasterStateClient
end

return getBlasterStateAttribute
