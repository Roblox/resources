-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Health = require(ReplicatedStorage.Core.Libraries.Health)
local ScoreHandler = require(ServerScriptService.Core.Systems.RoundServer.ScoreHandler)
local TeamHandler = require(ServerScriptService.Core.Systems.RoundServer.TeamHandler)

local Types = require(ServerScriptService.Core.Systems.RoundServer.Types)
local disconnectAndClear = require(ReplicatedStorage.Core.Utility.disconnectAndClear)

local MODE_NAME = "FreeForAll"
local REQUIRED_SCORE_TO_WIN = 5
local MINIMUM_PLAYERS = 1

local connections = {}

local FreeForAll = {
	mode = MODE_NAME,
}

function FreeForAll.canStart(): boolean
	return #Players:GetPlayers() >= MINIMUM_PLAYERS
end

function FreeForAll.shouldEnd(): boolean
	for _, score in ScoreHandler.getAllScores() do
		if score >= REQUIRED_SCORE_TO_WIN then
			return true
		end
	end

	return false
end

function FreeForAll.getParticipants(): { Types.Participant }
	local participants: { Types.Participant } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(participants, player.Character)
		end
	end

	return participants
end

function FreeForAll.onStop(): Types.GameModeStopData
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

	disconnectAndClear(connections)
	TeamHandler.clearAllTeamsData()
	ScoreHandler.resetScores()

	return { winners = winners }
end

function FreeForAll.onStart(): ()
	local participants = FreeForAll.getParticipants()
	for index, participant in participants do
		local teamName = tostring(index)
		if not TeamHandler.getTeamData(teamName) then
			TeamHandler.registerTeam(teamName)
		end

		TeamHandler.addToTeam(participant, teamName)
		TeamHandler.teleportToTeamSpawn(participant)
		Health.resetHealth(participant)
	end
end

return FreeForAll :: Types.GameModeDefinition
