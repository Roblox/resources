-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type QuestUpdate =
	{
		type: "update",
		id: string,
		name: string,
		progress: number,
		maxProgress: number,
		description: string,
	}
	| {
		type: "complete",
		id: string,
		name: string,
		maxProgress: number,
		description: string,
	}
	| {
		type: "cancel",
		id: string,
	}

return nil
