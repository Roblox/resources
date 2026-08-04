--!nocheck
--[[
	Responsible for updating the state of a player's blaster on the Server based on their
	'playerState'. Also schedules the destruction of a player's force field if the player
	is selecting a blaster (e.g. when they spawn).
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerState = require(ReplicatedStorage.PlayerState)
local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local BlasterState = require(ReplicatedStorage.Blaster.BlasterState)
local scheduleDestroyForceField = require(ReplicatedStorage.scheduleDestroyForceField)

local attributeChangedConnectionByPlayer = {}

local function onPlayerStateChanged(player: Player, newPlayerState: string)
	-- Blaster state is 'Ready' only if player state is 'Playing'
	local newBlasterState = if newPlayerState == PlayerState.Playing then BlasterState.Ready else BlasterState.Disabled

	-- Schedule the destroy force field logic when the player begins playing
	if newPlayerState == PlayerState.Playing then
		scheduleDestroyForceField(player)
	end

	player:SetAttribute(PlayerAttribute.blasterStateServer, newBlasterState)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function()
		-- Set and handle the initial player state upon spawning: selecting a blaster
		player:SetAttribute(PlayerAttribute.playerState, PlayerState.SelectingBlaster)
		onPlayerStateChanged(player, PlayerState.SelectingBlaster)
	end)

	-- Handle all future updates to player state
	attributeChangedConnectionByPlayer[player] = player
		:GetAttributeChangedSignal(PlayerAttribute.playerState)
		:Connect(function()
			local newPlayerState = player:GetAttribute(PlayerAttribute.playerState)
			onPlayerStateChanged(player, newPlayerState)
		end)
end

-- Disconnect from the attribute changed connection when the player leaves
local function onPlayerRemoving(player: Player)
	if attributeChangedConnectionByPlayer[player] then
		attributeChangedConnectionByPlayer[player]:Disconnect()
		attributeChangedConnectionByPlayer[player] = nil
	end
end

-- Call onPlayerAdded for any players already in the game
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Call onPlayerAdded for all future players
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
