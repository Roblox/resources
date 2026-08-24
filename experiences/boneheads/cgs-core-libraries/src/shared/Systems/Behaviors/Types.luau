-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type Mode = "client" | "server" | "both" | "owner"
export type Step = "physics" | "heartbeat" | "render"

export type Behavior = {
	step: ((delta: number) -> ())?,
	cleanup: (() -> ())?,
}

export type BehaviorDefinition = {
	tag: string,
	order: number,
	mode: Mode,
	step: Step,
	create: (target: Instance) -> Behavior,
}

return nil
