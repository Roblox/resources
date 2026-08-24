-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type ItemActionParams = { [string]: any }

export type ItemAction = {
	read name: string,
	read displayOrder: number,
}

export type InventoryOwner = Player | Model

export type ItemBehaviorContext = {
	read owner: InventoryOwner,
	read inventory: InventoryOperations,
	read item: Item,
	read actionParams: ItemActionParams?,
}

export type ItemBehavior = {
	read getActions: (context: ItemBehaviorContext) -> { ItemAction },
	read onAction: (actionName: string, context: ItemBehaviorContext) -> (),
	read validate: ((actionName: string, context: ItemBehaviorContext) -> boolean)?,
}

export type ItemDefinition = {
	read id: string,
	read name: string,
	read description: string,
	read droppedModel: PVInstance?, -- TODO: Move this into data table per-project
	read behaviors: { ItemBehavior }?,
	read data: { [string]: any },
} & ({
	read stackable: true,
	read maxStack: number,
} | {
	read stackable: false,
})

export type ItemCompact = {
	uid: string,
	definitionId: string,
	count: number,
}

export type InventoryCompact = {
	items: { ItemCompact },
}

export type Item = {
	read uid: string,
	read definition: ItemDefinition,
	count: number,
}

export type ItemUpdate =
	{
		type: "addItem",
		uid: string,
		definitionId: string,
		count: number,
	}
	| {
		type: "updateItem",
		uid: string,
		count: number,
	}
	| {
		type: "removeItem",
		uid: string,
	}

export type InventoryOperations = {
	read getItems: () -> { Item },
	read getItemCount: (definition: ItemDefinition) -> number,
	read getItemByUid: (uid: string) -> Item?,
	read removeItemByUid: (uid: string, count: number) -> (),
	read removeItem: (definition: ItemDefinition, count: number) -> (),
	read addItem: (definition: ItemDefinition, count: number) -> (),
}

export type Inventory = InventoryOperations & {
	read applySnapshot: (items: { ItemCompact }) -> (),
	read applyUpdate: (updates: { ItemUpdate }) -> (),
	read subscribe: (callback: () -> ()) -> () -> (),
}

export type InventoryCoreAPI = {
	read start: (definitions: { [string]: ItemDefinition }) -> (),
}

export type InventoryClient = InventoryCoreAPI & {
	read getInventory: (target: Instance) -> Inventory?,
	read onInventoryCreated: (target: Instance, callback: (Inventory) -> ()) -> () -> (),
	read getItemActions: (item: Item) -> { ItemAction },
	read triggerItemAction: (actionName: string, itemId: string, actionParams: ItemActionParams?) -> (),
}

return nil
