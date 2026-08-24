-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Factions = require(ReplicatedStorage.Core.Libraries.Factions)
local Health = require(ReplicatedStorage.Core.Libraries.Health)
local ScoreHandler = require(ServerScriptService.Core.Systems.RoundServer.ScoreHandler)
local TeamHandler = require(ServerScriptService.Core.Systems.RoundServer.TeamHandler)

local Types = require(ServerScriptService.Core.Systems.RoundServer.Types)
local disconnectAndClear = require(ReplicatedStorage.Core.Utility.disconnectAndClear)

local MODE_NAME = "TeamDeathmatch"
local REQUIRED_SCORE_TO_WIN = 10
local TEAMS = { "Green", "Red" }
local MINIMUM_PLAYERS = 1

local connections = {}
local teamsSpawns = {
	["Green"] = Workspace:FindFirstChild("GreenTeamSpawn"),
	["Red"] = Workspace:FindFirstChild("RedTeamSpawn"),
}

local TeamDeathmatch = {
	mode = MODE_NAME,
}

local function clearParticipantFactions(participant: Types.Participant)
	for _, factionTag in Factions.getCharacterFactions(participant) do
		participant:RemoveTag(factionTag)
	end
end

function TeamDeathmatch.canStart(): boolean
	return #Players:GetPlayers() >= MINIMUM_PLAYERS
end

function TeamDeathmatch.shouldEnd(): boolean
	for _, score in ScoreHandler.getAllScores() do
		if score >= REQUIRED_SCORE_TO_WIN then
			return true
		end
	end

	return false
end

function TeamDeathmatch.getParticipants(): { Types.Participant }
	local participants: { Types.Participant } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(participants, player.Character)
		end
	end

	return participants
end

function TeamDeathmatch.onStop(): Types.GameModeStopData
	local winners = {}
	local winningScore = 0
	for source, score in ScoreHandler.getAllScores() do
		if score < REQUIRED_SCORE_TO_WIN then
			continue
		end

		if score > winningScore then
			winningScore = score
			winners = table.clone(TeamHandler.getTeamMembers(source))
		end
	end

	for _, participant in TeamDeathmatch.getParticipants() do
		clearParticipantFactions(participant)
	end

	disconnectAndClear(connections)
	TeamHandler.clearAllTeamsData()
	ScoreHandler.resetScores()

	return { winners = winners }
end

function TeamDeathmatch.onStart(): ()
	for _, team in TEAMS do
		if not TeamHandler.getTeamData(team) then
			TeamHandler.registerTeam(team)
			TeamHandler.setTeamSpawnLocation(team, teamsSpawns[team])
		end
	end

	local participants = TeamDeathmatch.getParticipants()
	for _, participant in participants do
		local greenTeamCount = TeamHandler.getTeamMembersCount(TEAMS[1])
		local redTeamCount = TeamHandler.getTeamMembersCount(TEAMS[2])
		local team = if greenTeamCount <= redTeamCount then TEAMS[1] else TEAMS[2]

		TeamHandler.addToTeam(participant, team)
		TeamHandler.teleportToTeamSpawn(participant)

		Health.resetHealth(participant)
	end
end

return TeamDeathmatch :: Types.GameModeDefinition
