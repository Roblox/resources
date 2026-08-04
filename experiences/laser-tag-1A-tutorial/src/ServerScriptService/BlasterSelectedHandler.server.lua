--[[
	Listens for when a player selects a blaster on the PickABlaster GUI.
	Updates the player's blaster type and their state to 'Playing'.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerState = require(ReplicatedStorage.PlayerState)
local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)

local blasterSelectedEvent = ReplicatedStorage.Instances.BlasterSelectedEvent

local function onBlasterSelectedEvent(player: Player, blasterType: string)
	-- To prevent exploiters from choosing a new blaster at any time, we only allow picking a new
	-- blaster if they are selecting a blaster (e.g. not while Playing)
	if player:GetAttribute(PlayerAttribute.playerState) ~= PlayerState.SelectingBlaster then
		warn(`Player {player.Name} attempted to pick a Blaster ({blasterType}) after they already selected a blaster.`)
		return
	end

	-- Update the player's blaster type
	player:SetAttribute(PlayerAttribute.blasterType, blasterType)

	-- Player has selected a weapon, update their state to 'Playing'
	player:SetAttribute(PlayerAttribute.playerState, PlayerState.Playing)
end

blasterSelectedEvent.OnServerEvent:Connect(onBlasterSelectedEvent)
