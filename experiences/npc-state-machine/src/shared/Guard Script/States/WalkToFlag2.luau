-- Walk to flag 2.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimpleStateMachine = require(ReplicatedStorage.Shared.SimpleStateMachine)

type State = SimpleStateMachine.State
type Context = SimpleStateMachine.Context

local Flag2 = CollectionService:GetTagged("Flag2")[1] :: Model
local function walkTowardsFlag2(context: Context)
	local humanoid = context.humanoid :: Humanoid
	humanoid:MoveTo(Flag2:GetPivot().Position)
end

local function setTargetFlag(context: Context)
	context.targetFlag = Flag2
end

local WalkToFlag2: State = {
	name = "WalkToFlag2",
	onStay = walkTowardsFlag2,
	onEnter = setTargetFlag,
}

return WalkToFlag2
