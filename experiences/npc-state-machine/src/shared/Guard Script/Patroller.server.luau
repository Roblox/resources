-- Level 2 Guard: Walks randomly between flags.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SimpleStateMachine = require(ReplicatedStorage.Shared.SimpleStateMachine)
local Idle = require(ReplicatedStorage.Shared["Guard Script"].States.Idle)
local WalkToRandomFlag = require(ReplicatedStorage.Shared["Guard Script"].States.WalkToRandomFlag)

-- Types.
type Context = SimpleStateMachine.Context
type StateMachine = SimpleStateMachine.StateMachine

-- Constants.
local CLOSE_TO_FLAG_DISTANCE = 7
local IDLE_DURATION = 1

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

-- Create transitions.
local transitions = {
	{
		startStates = { Idle },
		endState = WalkToRandomFlag,
		test = isIdleTimerDone,
	},
	{
		startStates = { WalkToRandomFlag },
		endState = Idle,
		test = isNearTargetFlag,
	},
}

-- Make the state machine.
local patrollerStateMachine: StateMachine = {
	name = "Patroller",
	activeState = Idle,
	transitions = transitions,
	context = {
		character = script.Parent,
		humanoid = script.Parent:FindFirstChildOfClass("Humanoid"),
		currentFlagNumber = 1,
		targetFlag = nil,
		idleStartTime = os.clock(),
	},
}

-- Tick the state machine every heartbeat.
RunService.Heartbeat:Connect(function()
	SimpleStateMachine.tick(patrollerStateMachine)
end)
