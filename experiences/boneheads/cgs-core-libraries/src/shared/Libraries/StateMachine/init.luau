-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local State = require(script.State)
local StateGraph = require(script.StateGraph)
local StateMachine = require(script.StateMachine)
local Transition = require(script.Transition)
local Types = require(script.Types)

export type StateGraph<T> = Types.StateGraph<T>
export type State<T> = Types.State<T>
export type Transition<T> = Types.Transition<T>
export type StateMachine<T> = Types.StateMachine<T>

return {
	createState = State.create,
	createStateGraph = StateGraph.create,
	createTransition = Transition.create,
	createTransitionFromTable = Transition.createFromTable,
	createStateMachine = StateMachine.create,
}
