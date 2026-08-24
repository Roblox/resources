-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)

type State<T> = Types.State<T>
type Transition<T> = Types.Transition<T>
type TransitionTest<T> = Types.TransitionTest<T>

local function create<T>(name: string, from: State<T>, to: State<T>, test: TransitionTest<T>): Transition<T>
	return table.freeze({
		name = name,
		from = { from },
		to = to,
		test = test,
	})
end

local function createFromTable<T>(name: string, from: { State<T> }, to: State<T>, test: TransitionTest<T>): Transition<T>
	return table.freeze({
		name = name,
		from = from,
		to = to,
		test = test,
	})
end

return {
	create = create,
	createFromTable = createFromTable,
}
