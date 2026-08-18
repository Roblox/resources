-- Walk to flag 1.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimpleStateMachine = require(ReplicatedStorage.Shared.SimpleStateMachine)

type State = SimpleStateMachine.State
type Context = SimpleStateMachine.Context

local Flag1 = CollectionService:GetTagged("Flag1")[1] :: Model
local function walkTowardsFlag1(context: Context)
	local humanoid = context.humanoid :: Humanoid
	humanoid:MoveTo(Flag1:GetPivot().Position)
end

local function setTargetFlag(context: Context)
	context.targetFlag = Flag1
end

local WalkToFlag1: State = {
	name = "WalkToFlag1",
	onStay = walkTowardsFlag1,
	onEnter = setTargetFlag,
}

return WalkToFlag1
