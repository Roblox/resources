--!nocheck
--[[
	Schedule to destroy a player's ForceField on the first of 3 events
		- timeout
		- first blast
		- respawn
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getBlasterStateAttribute = require(ReplicatedStorage.Blaster.getBlasterStateAttribute)
local BlasterState = require(ReplicatedStorage.Blaster.BlasterState)

local MAX_FORCE_FIELD_TIME = 8

local function destroyForceField(player: Player)
	if not player.Character then
		return
	end

	local forceField = player.Character:FindFirstChildWhichIsA("ForceField")
	if forceField then
		forceField:Destroy()
	end
end

local function scheduleDestroyForceField(player: Player?)
	if not player then
		player = Players.LocalPlayer
	end

	local attributeChangedConnection, characterRespawnedConnection
	local forceFieldEnded = false

	local function endForceField()
		-- Set a debounce flag to avoid trying to destroy the same force field more than once
		if forceFieldEnded then
			return
		end
		forceFieldEnded = true

		attributeChangedConnection:Disconnect()
		characterRespawnedConnection:Disconnect()
		destroyForceField(player)
	end

	-- This listens for the first activation of the blaster, disabling the ForceField
	-- to avoid an unfair situation where a player uses their blaster while protected by the ForceField
	local blasterStateAttribute = getBlasterStateAttribute()
	attributeChangedConnection = player:GetAttributeChangedSignal(blasterStateAttribute):Connect(function()
		local currentBlasterState = player:GetAttribute(blasterStateAttribute)
		if currentBlasterState == BlasterState.Blasting then
			endForceField()
		end
	end)

	-- This listens for the character to despawn, ensuring we cancel all our listeners and give the next
	-- character a fresh start if the character respawns (e.g. player resets) before the timeout ends or the player blasts
	characterRespawnedConnection = player.CharacterRemoving:Connect(endForceField)

	-- This handles the timeout for the ForceField after a blaster is selected
	task.delay(MAX_FORCE_FIELD_TIME, endForceField)
end

return scheduleDestroyForceField
