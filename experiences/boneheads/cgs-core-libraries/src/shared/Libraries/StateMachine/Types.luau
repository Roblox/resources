-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type StateContext = any

export type ContextFunction<T> = (context: T, stateContext: StateContext) -> ()
export type TransitionTest<T> = (context: T) -> boolean

export type State<T> = {
	read name: string,
	read defaultContext: (() -> StateContext)?,
	read onEnter: ContextFunction<T>?,
	read onStay: ContextFunction<T>?,
	read onExit: ContextFunction<T>?,
}

export type Transition<T> = {
	read from: { State<T> },
	read to: State<T>,
	read test: TransitionTest<T>,
}

export type StateGraph<T> = {
	read name: string,
	read startState: State<T>,
	read transitions: { Transition<T> },
	read getOutgoingTransitions: (State<T>) -> { Transition<T> },
}

export type StateMachine<T> = {
	stateGraph: StateGraph<T>,
	setContext: (key: string, value: any) -> (),
	setContextTable: (overrideTable: T) -> (),
	tick: () -> (),
	getActiveState: () -> State<T>,
}

return nil
