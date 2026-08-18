--[[
The types file.
Here, we define the structure for each of our table types.
]]

-- Context is information stored by a StateMachine.
-- It's passed to various functions.
export type Context = { [any]: any }

-- Each StateMachine has one active State.
-- A State represents what the NPC is doing.
-- We add functions to States to make them affect the NPC.
export type State = {
	name: string,
	onEnter: (Context) -> (),
	onExit: (Context) -> (),
	onStay: (Context) -> (),
}

-- TestFunctions are used by Transitions to decide if the
-- active state should switch over.
export type TestFunction = (Context) -> boolean

-- Transitions connect States with each other.
-- When their test returns true, they trigger the state
-- to switch to the endState.
export type Transition = {
	startStates: { State },
	endState: State,
	test: TestFunction,
}

-- A StateMachine is defined by a starting state, plus
-- all of the transitions that can occur.
-- We'll use the tick function to run the transitions
-- and change the state if one is true.
export type StateMachine = {
	name: string,
	activeState: State,
	transitions: { Transition },
	context: Context,
}

return nil
