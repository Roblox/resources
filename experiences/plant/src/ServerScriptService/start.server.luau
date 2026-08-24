--!strict

--[[
	Server startup script that loads all server modules and calls their appropriate
	initialization methods in the right order.
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local Market = require(ServerStorage.Source.Market)
local FarmManagerServer = require(ServerStorage.Source.Farm.FarmManagerServer)
local FtueManagerServer = require(ServerStorage.Source.FtueManagerServer)
local CharacterSpawner = require(ServerStorage.Source.CharacterSpawner)
local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local TagPlayers = require(ServerStorage.Source.TagPlayers)
local DefaultPlayerData = require(ServerStorage.Source.DefaultPlayerData)
local CollisionGroupManager = require(ServerStorage.Source.CollisionGroupManager)
local registerDevProducts = require(ServerStorage.Source.Utility.registerDevProducts)
local ReceiptProcessor = require(ServerStorage.Source.ReceiptProcessor)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

local safePlayerAdded = require(ReplicatedStorage.Source.Utility.safePlayerAdded)

print("To test, ensure this place is published and Enable Studio Access to API Services is enabled")

Network.startServer()
PlayerDataServer.start(DefaultPlayerData, "PlayerData", { ReceiptProcessor.receiptHistoryValueName })

local function onPlayerAdded(player: Player)
	if not PlayerDataServer.hasLoaded(player) then
		PlayerDataServer.waitForDataLoadAsync(player)
	end

	PlayerObjectsContainer.registerPlayer(player)
	TagPlayers.addTags(player)
	FarmManagerServer.addFarmForPlayer(player)
	FtueManagerServer.onPlayerAdded(player)
	CharacterSpawner.startRespawnLoop(player)
end

safePlayerAdded(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player: Player)
	CharacterSpawner.stopRespawnLoop(player)
	FarmManagerServer.removeFarmForPlayer(player)
	PlayerObjectsContainer.unregisterPlayer(player)
	PlayerDataServer.onPlayerRemovingAsync(player)
end)

registerDevProducts()
Market.start()
CollisionGroupManager.start()
FarmManagerServer.start()

-- There's a feature in studio allowing the player to reset their data. This handles
-- that request, essentially emulating the cleanup and startup steps from onPlayerRemoving
-- and onPlayerAdded, with a couple differences:
--  * The data cleanup step is skipped (e.g. does not unlock the session)
--  * Player's data is reset to DefaultPlayerData
Network.connectEvent(Network.RemoteEvents.ResetData, function(player: Player)
	local character = player.Character
	if not character then
		return
	end

	CharacterSpawner.stopRespawnLoop(player)

	player.Character = nil
	(character :: Model):Destroy()

	FarmManagerServer.removeFarmForPlayer(player)
	PlayerObjectsContainer.unregisterPlayer(player)

	if not PlayerDataServer.hasLoaded(player) then
		PlayerDataServer.waitForDataLoadAsync(player)
	end

	for _, key in pairs(PlayerDataKey) do
		-- The data gets cloned by PlayerDataServer.setValue, so it's okay
		-- to pass a reference to DefaultPlayerData here.
		PlayerDataServer.setValue(player, key, DefaultPlayerData[key])
	end

	onPlayerAdded(player)
end, Network.t.instanceOf("Player"))
