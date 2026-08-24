--!strict

--[[
	Creates objects linked to the lifetime of a player instance
	and provides getter methods by player instance for each object
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerPickupHandler = require(ServerStorage.Source.Farm.PlayerPickupHandler)
local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)

type PlayerObjects = {
	characterLoadedWrapper: CharacterLoadedWrapper.ClassType,
	pickupHandler: PlayerPickupHandler.ClassType,
}

local PlayerObjectsContainer = {}
PlayerObjectsContainer._objectsByPlayer = {} :: { [Player]: PlayerObjects }

function PlayerObjectsContainer.registerPlayer(player: Player)
	local characterLoadedWrapper = CharacterLoadedWrapper.new(player)

	PlayerObjectsContainer._objectsByPlayer[player] = {
		characterLoadedWrapper = characterLoadedWrapper,
		pickupHandler = PlayerPickupHandler.new(player, characterLoadedWrapper),
	}
end

function PlayerObjectsContainer.unregisterPlayer(player: Player)
	local playerObjects = PlayerObjectsContainer._objectsByPlayer[player]

	if playerObjects then
		for _, object in pairs(playerObjects) do
			object:destroy()
		end
	end

	PlayerObjectsContainer._objectsByPlayer[player] = nil
end

function PlayerObjectsContainer.getPlayerPickupHandler(player: Player)
	return PlayerObjectsContainer._objectsByPlayer[player].pickupHandler
end

function PlayerObjectsContainer.getCharacterLoadedWrapper(player: Player)
	return PlayerObjectsContainer._objectsByPlayer[player].characterLoadedWrapper
end

return PlayerObjectsContainer
