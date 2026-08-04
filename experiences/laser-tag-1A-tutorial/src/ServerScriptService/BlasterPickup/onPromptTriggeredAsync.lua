--[[
	Handles the proximity prompt trigger logic, including
		- Removing the blaster model to show the weapon has been taken
		- Disabling the pickup for other players
		- Setting attributes on the player for the new blaster
		- Enabling the pickup after some time (PICKUP_RESPAWN_TIME)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local BlasterPickupAttribute = require(ReplicatedStorage.BlasterPickupAttribute)
local BlasterState = require(ReplicatedStorage.Blaster.BlasterState)

local PICKUP_RESPAWN_TIME = 20

local function onPromptTriggeredAsync(promptObject: ProximityPrompt, player: Player)
	if not promptObject.Enabled then
		-- Debounce in case two players trigger it at the same time
		return
	end

	-- Disable promptObject, remove blaster model
	promptObject.Enabled = false

	local blasterPickup = promptObject:FindFirstAncestor("BlasterPickup")
	local blaster = blasterPickup:FindFirstChildWhichIsA("Model")
	blaster.Parent = nil

	local blasterType = blasterPickup:GetAttribute(BlasterPickupAttribute.blasterType)
	assert(blasterType, `Missing BlasterType attribute on pickup {blasterPickup:GetFullName()}`)

	-- Set blaster attributes for the new blasterType
	player:SetAttribute(PlayerAttribute.blasterType, blasterType)
	player:SetAttribute(PlayerAttribute.blasterStateServer, BlasterState.Ready)

	-- Re-enable promptObject, add back blaster model
	task.wait(PICKUP_RESPAWN_TIME)
	blaster.Parent = blasterPickup
	promptObject.Enabled = true
end

return onPromptTriggeredAsync
