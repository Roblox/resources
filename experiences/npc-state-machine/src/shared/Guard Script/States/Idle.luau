-- Do nothing for a moment.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimpleStateMachine = require(ReplicatedStorage.Shared.SimpleStateMachine)

type State = SimpleStateMachine.State
type Context = SimpleStateMachine.Context

local Idle: State = {
	name = "Idle",
	onEnter = function(context: Context)
		context.idleStartTime = os.clock()
	end,
}

return Idle
