-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type ItemModel = Model

export type ItemController = {
	onEquip: () -> (),
	onUnequip: () -> (),
	onActivate: () -> (),
	onDeactivate: () -> (),

	cleanup: () -> (),
	getModel: () -> ItemModel,
}

export type ItemDefinitionName = string
export type ItemDefinition = {
	constructor: (itemModel: ItemModel, character: Model) -> ItemController,
}

return nil
