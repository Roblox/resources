-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local createCharacter = require(script.createCharacter)
local loadPlayerCharacter = require(script.loadPlayerCharacter)

local remotes = ReplicatedStorage.Core.Systems.Characters.Remotes

local playerCharacterOverrides: { [Player]: Model } = {}
local defaultCharacterTemplate: Model
local autoSpawn = true

local function getCharacterTemplate(player: Player): Model
	if playerCharacterOverrides[player] then
		return playerCharacterOverrides[player]
	end
	return defaultCharacterTemplate
end

local function onPlayerAdded(player: Player)
	if autoSpawn then
		local template = getCharacterTemplate(player)
		task.defer(loadPlayerCharacter, player, template)
	end
end

local function onPlayerRemoving(player: Player)
	if playerCharacterOverrides[player] then
		playerCharacterOverrides[player] = nil
	end
end

local function onResetCharacter(player: Player)
	local template = getCharacterTemplate(player)
	loadPlayerCharacter(player, template)
end

local CharactersServer = {
	createCharacter = createCharacter,
}

function CharactersServer.setPlayerTemplate(player: Player, template: Model?)
	playerCharacterOverrides[player] = template
end

function CharactersServer.setDefaultTemplate(template: Model)
	defaultCharacterTemplate = template
end

function CharactersServer.loadCharacter(player: Player): Model
	local template = getCharacterTemplate(player)
	return loadPlayerCharacter(player, template)
end

function CharactersServer.setAutoSpawn(setAutoSpawn: boolean)
	autoSpawn = setAutoSpawn
end

function CharactersServer.start(characterTemplate: Model, initAutoSpawn: boolean?)
	if initAutoSpawn ~= nil then
		autoSpawn = initAutoSpawn
	end

	defaultCharacterTemplate = characterTemplate
	remotes.ResetCharacter.OnServerEvent:Connect(onResetCharacter)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return CharactersServer
