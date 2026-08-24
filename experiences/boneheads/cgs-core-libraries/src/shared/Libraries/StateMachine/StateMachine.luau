-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)

type State<T> = Types.State<T>
type StateGraph<T> = Types.StateGraph<T>
type StateMachine<T> = Types.StateMachine<T>

local function create<T>(stateGraph: StateGraph<T>): StateMachine<T>
	local activeState: State<T> = stateGraph.startState
	local hasTicked = false
	local context = {}
	local stateContexts: { [State<T>]: Types.StateContext } = {}

	local function getActiveState(): State<T>
		return activeState
	end

	-- TODO: Add a dynamic type function for this to match context keys
	local function setContext(key: string, value: any)
		context[key] = value
	end

	local function setContextTable<T>(overrideTable: T)
		context = overrideTable
	end

	local function getOrCreateStateContext(state: State<T>): Types.StateContext
		if not stateContexts[state] then
			if state.defaultContext then
				stateContexts[state] = state.defaultContext()
			else
				stateContexts[state] = {}
			end
		end

		return stateContexts[state]
	end

	local function tick()
		if not hasTicked then
			if activeState.onEnter then
				activeState.onEnter(context, getOrCreateStateContext(activeState))
			end
			hasTicked = true
		end

		local outgoingTransitions = stateGraph.getOutgoingTransitions(activeState)

		for _, transition in outgoingTransitions do
			if transition.test(context) then
				if activeState.onExit then
					activeState.onExit(context, getOrCreateStateContext(activeState))
				end

				activeState = transition.to

				if activeState.onEnter then
					activeState.onEnter(context, getOrCreateStateContext(activeState))
				end

				return
			end
		end

		if activeState.onStay then
			activeState.onStay(context, getOrCreateStateContext(activeState))
		end
	end

	return {
		stateGraph = stateGraph,
		getActiveState = getActiveState,
		setContext = setContext,
		setContextTable = setContextTable,
		tick = tick,
	}
end

return {
	create = create,
}
