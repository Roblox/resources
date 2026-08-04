--[[
	Checks if the local player is able to blast their blaster.

	The blaster state is stored on the local player's 'blasterStateClient' attribute.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local BlasterState = require(ReplicatedStorage.Blaster.BlasterState)

local localPlayer = Players.LocalPlayer

local function canLocalPlayerBlast(): boolean
	return localPlayer:GetAttribute(PlayerAttribute.blasterStateClient) == BlasterState.Ready
end

return canLocalPlayerBlast
