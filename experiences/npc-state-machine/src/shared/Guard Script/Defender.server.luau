-- Level 3 Guard: Walks between flags, and attacks the player if they get too close.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SimpleStateMachine = require(ReplicatedStorage.Shared.SimpleStateMachine)
local Idle = require(ReplicatedStorage.Shared["Guard Script"].States.Idle)
local WalkToRandomFlag = require(ReplicatedStorage.Shared["Guard Script"].States.WalkToRandomFlag)
local Attack = require(ReplicatedStorage.Shared["Guard Script"].States.Attack)

-- Types.
type Context = SimpleStateMachine.Context
type StateMachine = SimpleStateMachine.StateMachine

-- Constants.
local CLOSE_TO_FLAG_DISTANCE = 7
local IDLE_DURATION = 1
local DETECTION_RANGE = 50

-- Check if the NPC is near the target flag.
local function isNearTargetFlag(context: Context): boolean
	local character = context.character :: Model
	local characterPosition = character:GetPivot().Position
	local flagPosition = context.targetFlag:GetPivot().Position :: Vector3
	return (characterPosition - flagPosition).Magnitude <= CLOSE_TO_FLAG_DISTANCE
end

-- Check if the idle timer has elapsed.
local function isIdleTimerDone(context: Context): boolean
	return os.clock() - context.idleStartTime >= IDLE_DURATION
end

-- Check if a player is within detection range.
local function isPlayerNearby(context: Context): boolean
	local character = context.character :: Model
	local characterPosition = character:GetPivot().Position

	for _, player in Players:GetPlayers() do
		local playerCharacter = player.Character
		if playerCharacter then
			local playerPosition = playerCharacter:GetPivot().Position
			if (characterPosition - playerPosition).Magnitude <= DETECTION_RANGE then
				context.targetPlayer = player
				return true
			end
		end
	end
	return false
end

-- Create transitions.
local transitions = {
	-- If a player is nearby, attack.
	{
		startStates = { Idle, WalkToRandomFlag },
		endState = Attack,
		test = isPlayerNearby,
	},
	-- When idle timer is done, walk to a flag.
	{
		startStates = { Idle },
		endState = WalkToRandomFlag,
		test = isIdleTimerDone,
	},
	-- When we reach the flag, idle.
	{
		startStates = { WalkToRandomFlag },
		endState = Idle,
		test = isNearTargetFlag,
	},
}

-- Make the state machine.
local defenderStateMachine: StateMachine = {
	name = "Defender",
	activeState = Idle,
	transitions = transitions,
	context = {
		character = script.Parent,
		humanoid = script.Parent:FindFirstChildOfClass("Humanoid"),
		currentFlagNumber = 1,
		targetFlag = nil,
		targetPlayer = nil,
		idleStartTime = os.clock(),
		lastAttackTime = 0,
	},
}

-- Tick the state machine every heartbeat.
RunService.Heartbeat:Connect(function()
	SimpleStateMachine.tick(defenderStateMachine)
end)
