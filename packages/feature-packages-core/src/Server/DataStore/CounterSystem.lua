--!strict

--[[
	CounterSystem is a utility for tracking per user numerical counters and timers.
	Counters are stored in the shared FeaturePackages data store (FeaturePackagesStore).
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Protect the run context, this ModuleScript is only intended to run on the server
require(ReplicatedStorage.FeaturePackagesCore.Modules.ProtectRunContext).server()

local Players = game:GetService("Players")

local FeaturePackagesStore = require(ReplicatedStorage.FeaturePackagesCore.Server.DataStore.FeaturePackagesStore)
local TimerSystem = require(ReplicatedStorage.FeaturePackagesCore.Modules.TimerSystem)

local CounterSystem = {}

local TABLE_ID = "CounterSystem"

export type CounterId = string

export type CounterData = {
	numerical: { [CounterId]: number? },
	timer: { [CounterId]: TimerSystem.Timer? },
	onlineTimer: { [CounterId]: TimerSystem.Timer? },
}

export type CounterCallback = (player: Player, counterId: CounterId, delta: number?) -> ()

local playerInitialized: { [string]: boolean? } = {}

local function getKeyForPlayer(player: Player): string
	return `{player.UserId}`
end

local callbacks: { [CounterId]: { CounterCallback }? } = {}

-- Call all the callbacks for a given player/counter
local function handleCallbacks(player: Player, counterId: CounterId, delta: number?)
	local counterCallbacks = callbacks[counterId]
	if not counterCallbacks then
		return -- There are no callbacks set for this timer, do nothing
	end

	for _, callback in counterCallbacks do
		callback(player, counterId, delta)
	end
end

-- Add a function to call when a specific counter changes.
-- Called for both timers and numerical counters, users should just check the correct type.
function CounterSystem.addChangedHandler(counterId: CounterId, callback: CounterCallback)
	local counterCallbacks = callbacks[counterId] or {}

	-- If the underlying list is nil, initialize it to the new one.
	if not callbacks[counterId] then
		callbacks[counterId] = counterCallbacks
	end

	table.insert(counterCallbacks, callback)
end

-- Remove a function from the list of handlers when a counter changes.
function CounterSystem.removeChangedHandler(counterId: CounterId, callback: CounterCallback)
	local counterCallbacks = callbacks[counterId]
	if not counterCallbacks then
		return
	end

	for index, otherCallback in counterCallbacks do
		if otherCallback == callback then
			table.remove(counterCallbacks, index)
			return
		end
	end
end

-- When a player joins, unsuspend all their online only timers.
local function onPlayerAdded(player: Player)
	-- Prevent duplicate initializations of the same player.
	if playerInitialized[getKeyForPlayer(player)] then
		return
	end

	playerInitialized[getKeyForPlayer(player)] = true

	local data: CounterData? = FeaturePackagesStore.getAsync(player, TABLE_ID)
	if not data then
		local newData = { numerical = {}, timer = {}, onlineTimer = {} }
		FeaturePackagesStore.setAsync(player, TABLE_ID, newData, true)
		return -- No timers to unsuspend, player is new.
	end

	for _, timer in data.onlineTimer do
		TimerSystem.unsuspend(timer)
	end
end

-- When a player's data is saved, suspend all their online only counters.
local function onSave(player: Player, data: CounterData, isRemoving: boolean?): CounterData
	for _, timer in data.onlineTimer do
		TimerSystem.suspend(timer)
	end

	-- Player left and is thus no longer initialized.
	if isRemoving then
		playerInitialized[getKeyForPlayer(player)] = nil
	end
	return data
end

-- Get all the information on a given player's counters.
local function getCounterData(player: Player): CounterData
	-- Events may be called in a non-ideal order across other modules that require this one.
	-- Handle now and ignore it later if that happens.
	if not playerInitialized[getKeyForPlayer(player)] then
		onPlayerAdded(player)
	end

	local data: CounterData = FeaturePackagesStore.getAsync(player, TABLE_ID)
	-- If multiple async requests are made, only one of them initializes the table.
	-- Wait for it.
	while not data do
		task.wait()
		data = FeaturePackagesStore.getAsync(player, TABLE_ID)
	end

	return data
end

-- Set the value of a given counter for a player.
function CounterSystem.setCounter(player: Player, counterId: CounterId, value: number?)
	local data = getCounterData(player)

	local previous = data.numerical[counterId] or 0
	local delta = (value or 0) - previous

	data.numerical[counterId] = value
	handleCallbacks(player, counterId, delta)
end

-- Add to the value of a given counter for a player.
function CounterSystem.addCounter(player: Player, counterId: CounterId, value: number)
	local data = getCounterData(player)

	local previous = data.numerical[counterId] or 0

	data.numerical[counterId] = previous + value
	handleCallbacks(player, counterId, value)
end

-- Get the value of a given counter for a player. Returns 0 if the counter is unset.
function CounterSystem.getCounter(player: Player, counterId: CounterId): number
	return getCounterData(player).numerical[counterId] or 0
end

-- Get the internal timer system reference to a timer that counts offline time.
local function getTimer(player: Player, counterId: CounterId): TimerSystem.Timer
	local data = getCounterData(player)

	local timer = data.timer[counterId]
	if not timer then
		local newTimer = TimerSystem.new()
		data.timer[counterId] = newTimer
		return newTimer
	end

	return timer
end

-- Get the internal timer system reference to a timer that does not count offline time.
local function getOnlineTimer(player: Player, counterId: CounterId): TimerSystem.Timer
	local data = getCounterData(player)

	local timer = data.onlineTimer[counterId]
	if not timer then
		local newTimer = TimerSystem.new()
		data.onlineTimer[counterId] = newTimer
		return newTimer
	end

	return timer
end

-- Start a timer counter by player/id.
function CounterSystem.startTimer(player: Player, counterId: CounterId)
	TimerSystem.start(getTimer(player, counterId))
	TimerSystem.start(getOnlineTimer(player, counterId))
	handleCallbacks(player, counterId)
end

-- Stop a timer counter by player/id.
function CounterSystem.stopTimer(player: Player, counterId: CounterId)
	TimerSystem.stop(getTimer(player, counterId))
	TimerSystem.stop(getOnlineTimer(player, counterId))
	handleCallbacks(player, counterId)
end

-- Check if a timer is running by player/id.
function CounterSystem.isTimerRunning(player: Player, counterId: CounterId): boolean
	return TimerSystem.isRunning(getTimer(player, counterId))
end

-- Get the number of elapsed seconds of a running timer including time offline.
function CounterSystem.getElapsedSeconds(player: Player, counterId: CounterId): TimerSystem.Seconds
	local timer = getTimer(player, counterId)
	return TimerSystem.getElapsedSeconds(timer)
end

-- Get the number of elapsed seconds of a running timer only including time online.
function CounterSystem.getElapsedSecondsOnline(player: Player, counterId: CounterId): TimerSystem.Seconds
	local timer = getOnlineTimer(player, counterId)
	return TimerSystem.getElapsedSeconds(timer)
end

-- Get the number of elapsed seconds of a timer for both online and offline time.
function CounterSystem.setElapsedSeconds(player: Player, counterId: CounterId, seconds: TimerSystem.Seconds)
	TimerSystem.setElapsedSeconds(getTimer(player, counterId), seconds)
	TimerSystem.setElapsedSeconds(getOnlineTimer(player, counterId), seconds)
	handleCallbacks(player, counterId)
end

local function initialize()
	FeaturePackagesStore.bindToTransform(TABLE_ID, onSave)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

initialize()

return CounterSystem
