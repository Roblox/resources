--[[
This file gives us a single entry point for all of the functions and types
we defined in other files.
]]

local Types = require(script.Types)
local CompositionTests = require(script.CompositionTests)
local tick = require(script.tick)

export type Context = Types.Context
export type State = Types.State
export type TestFunction = Types.TestFunction
export type Transition = Types.Transition
export type StateMachine = Types.StateMachine

return {
	AND = CompositionTests.AND,
	OR = CompositionTests.OR,
	NOT = CompositionTests.NOT,
	tick = tick,
}
