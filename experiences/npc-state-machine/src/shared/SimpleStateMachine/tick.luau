--[[
This is the StateMachine tick function.
It updates the StateMachine to the next state by checking each transition
coming out of the active state.
If one of the transition tests is true, we go along the transition
and end up at its end state.
We can provide onEnter and onExit functions to call when transitions occur,
and also an onStay function to call when a transition doesn't occur.
]]

local Types = require(script.Parent.Types)

type StateMachine = Types.StateMachine

local function tick(stateMachine: StateMachine)
	local activeState = stateMachine.activeState
	local context = stateMachine.context

	-- Check each transition to see if one is true.
	for _, transition in stateMachine.transitions do
		-- Check if this transition comes out of the active state.
		local fromActiveState = false
		for _, startState in transition.startStates do
			if startState == activeState then
				fromActiveState = true
				break
			end
		end

		-- If the transition comes out of the active state,
		-- run the test to see if we should take it.
		if fromActiveState and transition.test(context) then
			-- We transitioned. Run the onExit and onEnter functions,
			-- and change the active state.
			if activeState.onExit then
				activeState.onExit(context)
			end
			stateMachine.activeState = transition.endState

			if transition.endState.onEnter then
				transition.endState.onEnter(context)
			end
			return
		end
	end

	-- We didn't transition, so we run the onStay of the active state.
	if activeState.onStay then
		activeState.onStay(context)
	end
end

return tick
