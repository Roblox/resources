-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type DebugToggleKey = "PATHFINDING" | "BEHAVIOR"
export type DebugToggle = {
	ATTRIBUTE: string,
	ID_PREFIX: string,
}

export type IdMap<T> = { [string]: T }

export type IdEntry = {
	data: any,
	destroy: (any) -> (),
}

export type DebugTextBoxAdorning = {
	billboard: BillboardGui,
	label: TextLabel,
}

export type LabelEntry = {
	text: string,
	color: Color3?,
	textSize: number?,
}

export type DebugTextGroupAdorning = {
	billboard: BillboardGui,
	labels: { TextLabel },
}

export type DebugTextBoxAtPosition = {
	anchor: Part,
	billboard: BillboardGui,
	label: TextLabel,
}

export type DebugLine = {
	line: CylinderHandleAdornment,
	position1: Vector3,
	position2: Vector3,
}

export type ArcLines = {
	top: DebugLine,
	bottom: DebugLine,
	left: DebugLine,
	right: DebugLine,
	center: DebugLine,
	length: number,
	angle: number,
	origin: CFrame,
}

-- TODO Use a supertype

return nil
