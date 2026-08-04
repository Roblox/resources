--[[
	Used to simulate a blast on the Client.
	Sets the blaster state to "Blasting" until secondsBetweenBlasts has passed.

	laserBlastedBindableEvent and laserBlastedEvent events share the blast data
	with the Client and Server respectively.

	blastClient should not be directly called, instead use attemptBlastClient.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local BlasterState = require(ReplicatedStorage.Blaster.BlasterState)
local getBlasterConfig = require(ReplicatedStorage.Blaster.getBlasterConfig)
local generateBlastData = require(script.generateBlastData)

local laserBlastedBindableEvent = ReplicatedStorage.Instances.LaserBlastedBindableEvent
local laserBlastedEvent = ReplicatedStorage.Instances.LaserBlastedEvent

local localPlayer = Players.LocalPlayer

local function blastClient()
	-- Disable starting another blast by setting the state to Blasting
	localPlayer:SetAttribute(PlayerAttribute.blasterStateClient, BlasterState.Blasting)

	-- Generate data representing the blast and share the data
	local blastData = generateBlastData()
	laserBlastedBindableEvent:Fire(blastData)
	laserBlastedEvent:FireServer(blastData)

	local blasterConfig = getBlasterConfig()
	local secondsBetweenBlasts = blasterConfig:GetAttribute("secondsBetweenBlasts")

	-- Re-enable the blaster after secondsBetweenBlasts if the state is still 'Blasting'
	task.delay(secondsBetweenBlasts, function()
		local currentState = localPlayer:GetAttribute(PlayerAttribute.blasterStateClient)
		if currentState == BlasterState.Blasting then
			localPlayer:SetAttribute(PlayerAttribute.blasterStateClient, BlasterState.Ready)
		end
	end)
end

return blastClient
