-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)

type State<T> = Types.State<T>
type Transition<T> = Types.Transition<T>
type StateGraph<T> = Types.StateGraph<T>

local function create<T>(name: string, startState: State<T>, transitions: { Transition<T> }): StateGraph<T>
	local outgoingTransitions: { [State<T>]: { Transition<T> } } = {}
	for _, transition in transitions do
		for _, fromState in transition.from do
			if not outgoingTransitions[fromState] then
				outgoingTransitions[fromState] = { transition }
			else
				table.insert(outgoingTransitions[fromState], transition)
			end
		end
	end

	local function getOutgoingTransitions(state: State<T>): { Transition<T> }
		return outgoingTransitions[state] or {}
	end

	return table.freeze({
		name = name,
		startState = startState,
		transitions = transitions,
		getOutgoingTransitions = getOutgoingTransitions,
	})
end

return {
	create = create,
}
