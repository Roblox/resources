-- Walk towards a random adjacent flag in the patrol sequence.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimpleStateMachine = require(ReplicatedStorage.Shared.SimpleStateMachine)

type State = SimpleStateMachine.State
type Context = SimpleStateMachine.Context

-- Get all four flags.
local flags = {
	CollectionService:GetTagged("Flag1")[1],
	CollectionService:GetTagged("Flag2")[1],
	CollectionService:GetTagged("Flag3")[1],
	CollectionService:GetTagged("Flag4")[1],
}

-- Pick the next flag number: current +/- 1, wrapping around.
local NUM_FLAGS = 4
local function pickNextFlagNumber(currentFlagNumber: number): number
	if math.random(1, 2) == 1 then
		return (currentFlagNumber % NUM_FLAGS) + 1
	else
		return ((currentFlagNumber - 2) % NUM_FLAGS) + 1
	end
end

-- Pick the next flag and store it in context.
local function setNextFlag(context: Context)
	local nextFlagNumber = pickNextFlagNumber(context.currentFlagNumber)
	context.currentFlagNumber = nextFlagNumber
	context.targetFlag = flags[nextFlagNumber]
end

-- Walk towards the target flag.
local function walkTowardsFlag(context: Context)
	local humanoid = context.humanoid :: Humanoid
	humanoid:MoveTo(context.targetFlag:GetPivot().Position)
end

local WalkToRandomFlag: State = {
	name = "WalkToRandomFlag",
	onEnter = setNextFlag,
	onStay = walkTowardsFlag,
}

return WalkToRandomFlag
