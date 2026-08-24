-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)

type ContextFunction<T> = Types.ContextFunction<T>
type State<T> = Types.State<T>
type StateContext = Types.StateContext

local function create<T>(
	name: string,
	onEnter: ContextFunction<T>?,
	onStay: ContextFunction<T>?,
	onExit: ContextFunction<T>?,
	defaultContext: (() -> StateContext)?
): State<T>
	return table.freeze({
		name = name,
		onEnter = onEnter,
		onStay = onStay,
		onExit = onExit,
		defaultContext = defaultContext,
	})
end

return {
	create = create,
}
