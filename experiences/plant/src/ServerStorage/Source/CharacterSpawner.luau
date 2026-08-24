--!strict

--[[
	Manually respawns characters when they die, used because
	Players.CharacterAutoLoads is false so that we can wait to spawn the character
	until their data is fully loaded.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local Signal = require(ReplicatedStorage.Source.Signal)

local CharacterSpawner = {}
CharacterSpawner.diedConnectionByPlayer = {} :: { [Player]: Signal.SignalConnection }

function CharacterSpawner.startRespawnLoop(player: Player)
	local characterLoadedWrapper = PlayerObjectsContainer.getCharacterLoadedWrapper(player)
	player:LoadCharacter()

	local diedConnection
	diedConnection = characterLoadedWrapper.died:Connect(function()
		task.wait(Players.RespawnTime)
		-- We just yielded for the respawn time, so we need to verify respawn conditions are still valid.
		-- Check if the diedConnection is still connected in case stopRespawnLoop was called during the yield,
		-- and check if the player is still connected, as they may have left the game
		if diedConnection._connected and player:IsDescendantOf(Players) then
			player:LoadCharacter()
		end
	end)

	CharacterSpawner.diedConnectionByPlayer[player] = diedConnection
end

function CharacterSpawner.stopRespawnLoop(player: Player)
	local connection = CharacterSpawner.diedConnectionByPlayer[player]

	if connection then
		connection:Disconnect()
		CharacterSpawner.diedConnectionByPlayer[player] = nil
	end
end

return CharacterSpawner
