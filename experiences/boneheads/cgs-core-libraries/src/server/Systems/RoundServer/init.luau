-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Constants)
local Types = require(script.Types)

local DEBUG = RunService:IsStudio() and false

local gameModes: { [string]: Types.GameModeDefinition } = {}
local currentGameMode: Types.GameModeDefinition

local roundState = Constants.DEFAULT_ROUND_STATE
local roundDuration = Constants.DEFAULT_ROUND_DURATION
local intermissionDuration = Constants.DEFAULT_INTERMISSION_DURATION

local roundStepConnection: RBXScriptConnection? = nil
local roundStopThread: thread? = nil

local Round = {}

local function debugPrint(...: any): ()
	if DEBUG then
		print("[RoundService] -", ...)
	end
end

local function _onPlayerAdded(player: Player): ()
	debugPrint(`Player {player.Name} joined the game.`)
end

local function getWinnerUserIds(winners: { Types.Participant }): string
	local userIds = {}

	for _, winner in winners do
		local player = Players:GetPlayerFromCharacter(winner)
		if player then
			table.insert(userIds, tostring(player.UserId))
		end
	end

	return table.concat(userIds, ",")
end

function Round.setRoundState(newState: Types.RoundState): ()
	Workspace:SetAttribute(Constants.ROUND_STATE_ATTRIBUTE, newState)
	roundState = newState
	debugPrint(`Round state set to {newState}`)
end

function Round.getRoundState(): Types.RoundState
	return roundState
end

function Round.setGameMode(gameMode: Types.GameMode): ()
	assert(gameModes[gameMode], `Game mode module not found: {gameMode}`)
	currentGameMode = gameModes[gameMode]
	debugPrint(`Game mode set to {gameMode}`)
end

function Round.getGameMode(): Types.GameMode?
	return if currentGameMode then currentGameMode.mode else nil
end

function Round.setRoundDuration(duration: number): ()
	roundDuration = duration
end

function Round.getRoundDuration(): number
	return roundDuration
end

function Round.setIntermissionDuration(duration: number): ()
	intermissionDuration = duration
end

function Round.getIntermissionDuration(): number
	return intermissionDuration
end

function Round.stopRound(): ()
	if Round.getRoundState() ~= "InProgress" then
		warn("Attempted to stop round while not in progress.")
		return
	end

	if not currentGameMode then
		warn("Attempted to stop round without a game mode set.")
		return
	end

	if roundStepConnection then
		roundStepConnection:Disconnect()
		roundStepConnection = nil
	end

	if roundStopThread then
		task.cancel(roundStopThread)
		roundStopThread = nil
	end

	Workspace:SetAttribute(Constants.ROUND_END_TIMESTAMP_ATTRIBUTE, nil)

	local participants = currentGameMode.getParticipants()
	for _, participant in participants do
		participant:SetAttribute(Constants.IN_ROUND_ATTRIBUTE, nil)
	end

	local stopData = currentGameMode.onStop()
	local winnerUserIds = ""
	if stopData and stopData.winners and #stopData.winners > 0 then
		winnerUserIds = getWinnerUserIds(stopData.winners)
	end

	Workspace:SetAttribute(Constants.ROUND_WINNER_USER_IDS_ATTRIBUTE, winnerUserIds)

	debugPrint("Round stopped.")
	Round.intermission()
end

function Round.startRound(): ()
	local _roundState = Round.getRoundState()
	if not (_roundState == "Intermission" or _roundState == "Paused") then
		warn("Attempted to start round while not in intermission / paused state.")
		return
	end

	if not currentGameMode then
		warn("Attempted to start round without a game mode set.")
		return
	end

	if currentGameMode.onIntermissionEnd then
		currentGameMode.onIntermissionEnd()
	end

	Workspace:SetAttribute(Constants.ROUND_WINNER_USER_IDS_ATTRIBUTE, nil)

	local startTimestamp = Workspace:GetServerTimeNow()
	Workspace:SetAttribute(Constants.ROUND_START_TIMESTAMP_ATTRIBUTE, startTimestamp)

	local effectiveRoundDuration = currentGameMode.roundDuration or roundDuration
	Workspace:SetAttribute(Constants.ROUND_END_TIMESTAMP_ATTRIBUTE, startTimestamp + effectiveRoundDuration)
	Workspace:SetAttribute(Constants.INTERMISSION_END_TIMESTAMP_ATTRIBUTE, nil)

	currentGameMode.onStart()

	local participants = currentGameMode.getParticipants()
	for _, participant in participants do
		participant:SetAttribute(Constants.IN_ROUND_ATTRIBUTE, true)
	end

	Round.setRoundState("InProgress")
	debugPrint("Round started.")

	roundStepConnection = RunService.Heartbeat:Connect(function()
		if Round.getRoundState() == "InProgress" and currentGameMode and currentGameMode.shouldEnd() then
			Round.stopRound()
		end
	end)

	-- selene: allow(incorrect_standard_library_use)
	if math.isfinite(effectiveRoundDuration) then
		roundStopThread = task.delay(effectiveRoundDuration, function()
			roundStopThread = nil
			Round.stopRound()
		end)
	end
end

function Round.intermission(): ()
	Round.setRoundState("Intermission")

	local effectiveIntermissionDuration = currentGameMode.intermissionDuration or intermissionDuration
	Workspace:SetAttribute(
		Constants.INTERMISSION_END_TIMESTAMP_ATTRIBUTE,
		Workspace:GetServerTimeNow() + effectiveIntermissionDuration
	)

	debugPrint(`Intermission. Waiting for {effectiveIntermissionDuration} seconds before starting next round...`)

	if currentGameMode.onIntermissionStart then
		currentGameMode.onIntermissionStart()
	end

	task.delay(effectiveIntermissionDuration, function()
		if not currentGameMode.canStart() then
			Round.setRoundState("Paused")
			while not currentGameMode.canStart() do
				debugPrint("Not enough players to start the round. Waiting...")
				task.wait()
			end
		end

		Round.startRound()
	end)
end

function Round.autoLoad(target: Instance)
	for _, module in target:GetChildren() do
		assert(
			module:IsA("ModuleScript"),
			`Gamemode definition modules must be ModuleScripts. Found {module.ClassName} named {module.Name}`
		)
		local gameModeDefinition: Types.GameModeDefinition = require(module) :: any
		gameModes[gameModeDefinition.mode] = gameModeDefinition
	end
end

function Round.start(): ()
	for _, player in Players:GetPlayers() do
		_onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(_onPlayerAdded)

	debugPrint(`Started successfully!`)

	Round.setGameMode(Constants.DEFAULT_GAME_MODE)
	Round.intermission()
end

return Round
