-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Constants = require(ReplicatedStorage.Core.Systems.Teleport.Constants)
local StudioSimulator = require(script.StudioSimulator)
local Types = require(script.Types)
local retryWithBackoffAsync = require(script.retryWithBackoffAsync)

local Remotes = ReplicatedStorage.Core.Systems.Teleport.Remotes

local config: Types.TeleportConfig = {
	maxRetries = Constants.DEFAULT_MAX_RETRIES,
	initialBackoffSeconds = Constants.DEFAULT_INITIAL_BACKOFF_SECONDS,
	maxBackoffSeconds = Constants.DEFAULT_MAX_BACKOFF_SECONDS,
	backoffMultiplier = Constants.DEFAULT_BACKOFF_MULTIPLIER,
	studioTestConfig = nil,
}

local isStudio = false
local playerStatuses: { [Player]: Types.TeleportStatusPayload } = {}
local playerGenerations: { [Player]: number } = {}
local statusCallbacks: { (player: Player, payload: Types.TeleportStatusPayload) -> () } = {}

local TeleportServer = {}

local function broadcastStatus(player: Player, payload: Types.TeleportStatusPayload)
	playerStatuses[player] = payload

	if player.Parent then
		Remotes.TeleportStatusUpdate:FireClient(player, payload)
	end

	for _, callback in statusCallbacks do
		task.spawn(callback, player, payload)
	end
end

local function createPayload(
	status: Types.TeleportStatus,
	placeId: number,
	attemptNumber: number,
	errorMessage: string?,
	destinationName: string?
): Types.TeleportStatusPayload
	return {
		status = status,
		placeId = placeId,
		destinationName = destinationName,
		attemptNumber = attemptNumber,
		maxRetries = config.maxRetries,
		errorMessage = errorMessage,
		timestamp = os.clock(),
	}
end

function TeleportServer.teleportPlayer(
	player: Player,
	placeId: number,
	teleportData: { [string]: any }?,
	destinationName: string?
)
	if not player.Parent then
		warn(`[TeleportServer] teleportPlayer called for {player.Name} who is not in the game`)
		return
	end
	if placeId <= 0 then
		warn(`[TeleportServer] teleportPlayer called with invalid placeId {placeId} for {player.Name}`)
		return
	end

	local currentStatus = playerStatuses[player]
	if
		currentStatus
		and currentStatus.status ~= Constants.STATUS_IDLE
		and currentStatus.status ~= Constants.STATUS_FAILED
	then
		warn(`[TeleportServer] Player {player.Name} already has an active teleport (status: {currentStatus.status})`)
		return
	end

	local generation = (playerGenerations[player] or 0) + 1
	playerGenerations[player] = generation

	broadcastStatus(player, createPayload(Constants.STATUS_QUEUED, placeId, 0, nil, destinationName))

	task.spawn(function()
		local function shouldCancel(): boolean
			if not player.Parent then
				return true
			end
			if playerGenerations[player] ~= generation then
				return true
			end
			local status = playerStatuses[player]
			return status == nil or status.status == Constants.STATUS_IDLE
		end

		local function onAttempt(attemptNumber: number)
			if playerGenerations[player] ~= generation then
				return
			end
			broadcastStatus(
				player,
				createPayload(Constants.STATUS_TELEPORTING, placeId, attemptNumber, nil, destinationName)
			)
		end

		local function onRetrying(attemptNumber: number, errorMessage: string)
			if playerGenerations[player] ~= generation then
				return
			end
			broadcastStatus(
				player,
				createPayload(Constants.STATUS_RETRYING, placeId, attemptNumber, errorMessage, destinationName)
			)
		end

		local function doTeleport()
			if isStudio then
				local testConfig = config.studioTestConfig
				StudioSimulator.simulateTeleport(
					player,
					placeId,
					Constants.STUDIO_TELEPORT_DELAY_SECONDS,
					if testConfig then testConfig.simulateFailure else false,
					if testConfig then testConfig.failureCount else 0,
					shouldCancel
				)
			else
				local teleportOptions = Instance.new("TeleportOptions")
				if teleportData then
					teleportOptions:SetTeleportData(teleportData)
				end
				TeleportService:TeleportAsync(placeId, { player }, teleportOptions)
				teleportOptions:Destroy()
			end
		end

		local success, errorMessage, finalAttempt =
			retryWithBackoffAsync(doTeleport, shouldCancel, onAttempt, onRetrying, {
				maxRetries = config.maxRetries,
				initialBackoffSeconds = config.initialBackoffSeconds,
				maxBackoffSeconds = config.maxBackoffSeconds,
				backoffMultiplier = config.backoffMultiplier,
			})

		if not player.Parent or playerGenerations[player] ~= generation then
			return
		end

		if success then
			broadcastStatus(
				player,
				createPayload(Constants.STATUS_SUCCEEDED, placeId, finalAttempt, nil, destinationName)
			)
		else
			broadcastStatus(
				player,
				createPayload(Constants.STATUS_FAILED, placeId, finalAttempt, errorMessage, destinationName)
			)
		end
	end)
end

function TeleportServer.teleportPlayers(
	players: { Player },
	placeId: number,
	teleportData: { [string]: any }?,
	destinationName: string?
)
	for _, player in players do
		TeleportServer.teleportPlayer(player, placeId, teleportData, destinationName)
	end
end

function TeleportServer.cancelTeleport(player: Player)
	playerGenerations[player] = (playerGenerations[player] or 0) + 1
	broadcastStatus(player, createPayload(Constants.STATUS_IDLE, 0, 0))
	StudioSimulator.resetPlayer(player)
end

function TeleportServer.getStatus(player: Player): Types.TeleportStatus
	local payload = playerStatuses[player]
	if payload then
		return payload.status
	end
	return Constants.STATUS_IDLE
end

function TeleportServer.onStatusChanged(
	callback: (player: Player, payload: Types.TeleportStatusPayload) -> ()
): { Disconnect: () -> () }
	table.insert(statusCallbacks, callback)

	return {
		Disconnect = function()
			local index = table.find(statusCallbacks, callback)
			if index then
				table.remove(statusCallbacks, index)
			end
		end,
	}
end

function TeleportServer.start(configOverride: Types.TeleportConfig?)
	isStudio = RunService:IsStudio()

	if configOverride then
		config = configOverride
	end

	StudioSimulator.start()

	Remotes.TeleportInitiate.OnServerEvent:Connect(
		function(player: Player, placeId: number, teleportData: { [string]: any }?)
			if typeof(placeId) ~= "number" or placeId <= 0 then
				return
			end
			TeleportServer.teleportPlayer(player, placeId, teleportData)
		end
	)

	Players.PlayerRemoving:Connect(function(player: Player)
		playerStatuses[player] = nil
		playerGenerations[player] = nil
		StudioSimulator.cleanupPlayer(player)
	end)
end

return TeleportServer
