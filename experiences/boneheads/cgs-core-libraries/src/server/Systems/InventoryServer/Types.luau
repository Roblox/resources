-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(ReplicatedStorage.Core.Systems.Inventory.Types)
local Signal = require(ReplicatedStorage.Core.Libraries.Signal)

export type ItemDefinition = SharedTypes.ItemDefinition
export type Item = SharedTypes.Item
export type ItemCompact = SharedTypes.ItemCompact
export type ItemUpdate = SharedTypes.ItemUpdate
export type InventoryCompact = SharedTypes.InventoryCompact
export type ItemAction = SharedTypes.ItemAction
export type ItemActionParams = SharedTypes.ItemActionParams
export type ItemBehavior = SharedTypes.ItemBehavior

export type Inventory = SharedTypes.InventoryOperations & {
	read setReplicationEnabled: (player: Player, enabled: boolean) -> (),
	read isReplicatedToPlayer: (player: Player) -> boolean,
	read itemAdded: Signal.Signal<Item>,
	read itemRemoved: Signal.Signal<Item>,
	read itemChanged: Signal.Signal<Item>,
	read cleanup: () -> (),
}

export type InventoryOwner = SharedTypes.InventoryOwner

export type ItemBehaviorContext = {
	read owner: InventoryOwner,
	read inventory: Inventory,
	read item: Item,
	read actionParams: ItemActionParams?,
}

export type InventoryServer = SharedTypes.InventoryCoreAPI & {
	read addInventory: (target: Instance, initItems: { Item }?) -> Inventory,
	read removeInventory: (target: Instance) -> (),
	read getInventory: (target: Instance) -> Inventory?,
	read transferItem: (source: Instance, destination: Instance, uid: string, count: number) -> (),
	read transferItems: (
		source: Instance,
		destination: Instance,
		transfers: { { uid: string, count: number } }
	) -> (),
	read serializeItems: (items: { Item }) -> string,
	read deserializeItems: (serialized: string) -> { Item },
	read triggerItemAction: (
		owner: InventoryOwner,
		inventory: Inventory,
		actionName: string,
		itemUid: string,
		actionParams: ItemActionParams?
	) -> (),
}

return nil
