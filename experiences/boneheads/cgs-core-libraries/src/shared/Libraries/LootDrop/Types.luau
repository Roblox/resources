-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type CountRange = {
	min: number,
	max: number,
}

export type Count = number | CountRange

export type Drop = {
	data: any,
	count: Count,
	weight: number,
	type: "Drop",
}

export type DropTable = {
	entries: { Droppable },
	rollCount: Count,
	weight: number,
	forceUnique: boolean?,
	type: "DropTable",
}

export type Droppable = Drop | DropTable

export type RolledDrop = {
	data: any,
	count: number,
}

return nil
