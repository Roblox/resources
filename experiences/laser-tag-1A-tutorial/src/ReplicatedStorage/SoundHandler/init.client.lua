--[[
	Listens for when to play a blast sound for the local player.
	Also listens for blasts from the Server to replicate their sound.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local BlasterState = require(ReplicatedStorage.Blaster.BlasterState)
local playBlastSound = require(script.playBlastSound)

local replicateBlastEvent = ReplicatedStorage.Instances.ReplicateBlastEvent

local localPlayer = Players.LocalPlayer

localPlayer:GetAttributeChangedSignal(PlayerAttribute.blasterStateClient):Connect(function()
	local currentState = localPlayer:GetAttribute(PlayerAttribute.blasterStateClient)
	if currentState == BlasterState.Blasting then
		playBlastSound(localPlayer)
	end
end)

replicateBlastEvent.OnClientEvent:Connect(playBlastSound)
