-- Level 1 Guard: Walks between flags 1 and 2.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SimpleStateMachine = require(ReplicatedStorage.Shared.SimpleStateMachine)
local WalkToFlag1 = require(ReplicatedStorage.Shared["Guard Script"].States.WalkToFlag1)
local WalkToFlag2 = require(ReplicatedStorage.Shared["Guard Script"].States.WalkToFlag2)

-- Types.
type State = SimpleStateMachine.State
type Context = SimpleStateMachine.Context
type StateMachine = SimpleStateMachine.StateMachine

-- Check if our NPC is near the target flag.
local CLOSE_TO_FLAG_DISTANCE = 7
local function isNearTargetFlag(context: Context)
	local character = context.character :: Model

	local characterPosition = character:GetPivot().Position
	local flagPosition = context.targetFlag:GetPivot().Position :: Vector3

	return (characterPosition - flagPosition).Magnitude <= CLOSE_TO_FLAG_DISTANCE
end

-- Create our transitions.
local transitions = {
	-- When we reach Flag 1, go to Flag 2.
	{
		startStates = { WalkToFlag1 },
		endState = WalkToFlag2,
		test = isNearTargetFlag,
	},
	-- When we reach Flag 2, go to Flag 1.
	{
		startStates = { WalkToFlag2 },
		endState = WalkToFlag1,
		test = isNearTargetFlag,
	},
}

-- Make the state machine table.
local walkerStateMachine: StateMachine = {
	name = "Walker",
	activeState = WalkToFlag2,
	transitions = transitions,
	context = {
		character = script.Parent,
		humanoid = script.Parent:FindFirstChildOfClass("Humanoid"),
		targetFlag = CollectionService:GetTagged("Flag2")[1],
	},
}

-- Tick the state machine every heartbeat.
RunService.Heartbeat:Connect(function()
	SimpleStateMachine.tick(walkerStateMachine)
end)
