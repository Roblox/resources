-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type TriggerVolume = {
	onEnter: ((character: PVInstance) -> ())?,
	onExit: ((character: PVInstance) -> ())?,

	step: ((delta: number) -> ())?,
	cleanup: (() -> ())?,
}

export type TriggerVolumeDefinition = {
	filter: ((part: BasePart) -> PVInstance?)?,
	create: (volumePart: BasePart) -> TriggerVolume,
}

return nil
