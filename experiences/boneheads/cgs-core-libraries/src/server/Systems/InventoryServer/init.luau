-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = ReplicatedStorage.Core.Systems.Inventory.Remotes

local Signal = require(ReplicatedStorage.Core.Libraries.Signal)
local Types = require(script.Types)
local loadItemDefinitions = require(ReplicatedStorage.Core.Systems.Inventory.loadItemDefinitions)
local validateString = require(ServerScriptService.Core.Validation.validateString)

export type ItemDefinition = Types.ItemDefinition
export type Item = Types.Item
export type Inventory = Types.Inventory
export type InventoryCompact = Types.InventoryCompact
export type ItemCompact = Types.ItemCompact

local inventories: { [Instance]: Types.Inventory } = {}
local itemDefinitionsById: { [string]: Types.ItemDefinition } = {}
local readyPlayers: { [Player]: boolean } = {}

local InventoryServer = {}

function InventoryServer.addInventory(target: Instance, initCompact: InventoryCompact?): Types.Inventory
	assert(inventories[target] == nil, `Inventory already exists for target {target:GetFullName()}.`)

	-- The items for each definition id are sorted by largest count to smallest.
	-- This allows for more efficient stacking when adding items, and more efficient removal when removing items.
	local itemsByDefinitionId: { [string]: { Types.Item } } = {}
	local itemCountByDefinitionId: { [string]: number } = {}
	local itemByUid: { [string]: Types.Item } = {}
	local replicatedPlayers: { [Player]: boolean } = {}
	local itemAdded = Signal.create()
	local itemRemoved = Signal.create()
	local itemChanged = Signal.create()

	if initCompact then
		for _, itemCompact in initCompact.items do
			local item = InventoryServer.itemFromCompact(itemCompact)

			if not itemsByDefinitionId[item.definition.id] then
				itemsByDefinitionId[item.definition.id] = {}
			end
			table.insert(itemsByDefinitionId[item.definition.id], item)

			if not itemCountByDefinitionId[item.definition.id] then
				itemCountByDefinitionId[item.definition.id] = 0
			end

			itemCountByDefinitionId[item.definition.id] += item.count
			itemByUid[item.uid] = item
		end
	end

	local function getItems(): { Types.Item }
		local result: { Types.Item } = {}
		for _, items in itemsByDefinitionId do
			for _, item in items do
				table.insert(result, item)
			end
		end
		return result
	end

	local function getItemsCompact(): { Types.ItemCompact }
		local result: { Types.ItemCompact } = {}
		for _, items in itemsByDefinitionId do
			for _, item in items do
				local itemCompact: Types.ItemCompact = {
					uid = item.uid,
					definitionId = item.definition.id,
					count = item.count,
				}
				table.insert(result, itemCompact)
			end
		end
		return result
	end

	local function getMaxStack(definition: Types.ItemDefinition): number
		if definition.stackable then
			assert(
				definition.maxStack >= 1,
				`Stackable item definition {definition.id} must have a positive maxStack value.`
			)
			return definition.maxStack
		end
		return 1
	end

	local function getItemCount(definition: Types.ItemDefinition): number
		return itemCountByDefinitionId[definition.id] or 0
	end

	local function replicateUpdates(updates: { Types.ItemUpdate })
		for player in replicatedPlayers do
			Remotes.InventoryUpdate:FireClient(player, target, updates)
		end
	end

	local function addItem(definition: Types.ItemDefinition, count: number)
		assert(count > 0, `Count must be positive.`)

		local remaining = count
		local maxStack = getMaxStack(definition)
		local updates: { Types.ItemUpdate } = {}

		if not itemsByDefinitionId[definition.id] then
			itemsByDefinitionId[definition.id] = {}
		end
		local items = itemsByDefinitionId[definition.id]

		for _, item in items do
			if remaining == 0 then
				break
			end
			if item.count < maxStack then
				local space = maxStack - item.count
				local toAdd = math.min(remaining, space)
				item.count += toAdd
				remaining -= toAdd

				local update: Types.ItemUpdate = { type = "updateItem", uid = item.uid, count = item.count }
				table.insert(updates, update)
				itemChanged:Fire(item)
			end
		end

		while remaining > 0 do
			local toAdd = math.min(remaining, maxStack)
			local newItem: Types.Item = {
				uid = HttpService:GenerateGUID(false),
				definition = definition,
				count = toAdd,
			}

			table.insert(items, newItem)
			itemByUid[newItem.uid] = newItem
			remaining -= toAdd

			local update: Types.ItemUpdate = {
				type = "addItem",
				uid = newItem.uid,
				definitionId = definition.id,
				count = newItem.count,
			}
			table.insert(updates, update)
			itemAdded:Fire(newItem)
		end

		if itemCountByDefinitionId[definition.id] == nil then
			itemCountByDefinitionId[definition.id] = 0
		end

		itemCountByDefinitionId[definition.id] += count

		replicateUpdates(updates)
	end

	local function removeItem(definition: Types.ItemDefinition, count: number)
		assert(count > 0, `Count must be positive.`)

		local totalItemCount = getItemCount(definition)
		assert(
			totalItemCount >= count,
			`Cannot remove {count} of {definition.id} from inventory that only has {totalItemCount} available.`
		)

		local items = itemsByDefinitionId[definition.id]
		if not items then
			return
		end

		local remaining = count
		local updates: { Types.ItemUpdate } = {}

		for i = #items, 1, -1 do
			if remaining == 0 then
				break
			end
			local item = items[i]
			local toRemove = math.min(remaining, item.count)
			item.count -= toRemove
			remaining -= toRemove
			if item.count == 0 then
				local update: Types.ItemUpdate = { type = "removeItem", uid = item.uid }
				table.insert(updates, update)
				table.remove(items, i)
				itemRemoved:Fire(item)
				itemByUid[item.uid] = nil
			else
				local update: Types.ItemUpdate = { type = "updateItem", uid = item.uid, count = item.count }
				table.insert(updates, update)
				itemChanged:Fire(item)
			end
		end

		local newTotalItemCount = totalItemCount - count
		if newTotalItemCount == 0 then
			itemCountByDefinitionId[definition.id] = nil
			itemsByDefinitionId[definition.id] = nil
		else
			itemCountByDefinitionId[definition.id] = newTotalItemCount
		end

		replicateUpdates(updates)
	end

	local function removeItemByUid(uid: string, count: number)
		assert(count > 0, `Count must be positive.`)

		local item = itemByUid[uid]
		assert(item, `No item found for uid {uid}.`)
		assert(item.count >= count, `Cannot remove {count} of {uid} that only has {item.count} available.`)

		local definitionId = item.definition.id
		local items = itemsByDefinitionId[definitionId]
		local updates: { Types.ItemUpdate } = {}

		item.count -= count
		if item.count == 0 then
			local update: Types.ItemUpdate = { type = "removeItem", uid = uid }
			table.insert(updates, update)
			table.remove(items, table.find(items, item))
			itemByUid[uid] = nil
			itemRemoved:Fire(item)
		else
			local update: Types.ItemUpdate = { type = "updateItem", uid = uid, count = item.count }
			table.insert(updates, update)
			itemChanged:Fire(item)
		end

		local newTotalItemCount = (itemCountByDefinitionId[definitionId] or 0) - count
		if newTotalItemCount == 0 then
			itemCountByDefinitionId[definitionId] = nil
			itemsByDefinitionId[definitionId] = nil
		else
			itemCountByDefinitionId[definitionId] = newTotalItemCount
		end

		replicateUpdates(updates)
	end

	local function setReplicationEnabled(player: Player, enabled: boolean)
		if (not not replicatedPlayers[player]) == enabled then
			return
		end

		if enabled then
			replicatedPlayers[player] = true
			Remotes.InventorySnapshot:FireClient(player, target, getItemsCompact())
		else
			replicatedPlayers[player] = nil
			Remotes.InventorySnapshot:FireClient(player, target, nil)
		end
	end

	local function getItemByUid(uid: string): Types.Item?
		return itemByUid[uid]
	end

	local function isReplicatedToPlayer(player: Player): boolean
		return replicatedPlayers[player] == true
	end

	local function cleanup()
		itemAdded:DisconnectAll()
		itemRemoved:DisconnectAll()
		itemChanged:DisconnectAll()
	end

	local inventory: Types.Inventory = {
		getItems = getItems,
		getItemCount = getItemCount,
		addItem = addItem,
		removeItem = removeItem,
		removeItemByUid = removeItemByUid,
		getItemByUid = getItemByUid,
		setReplicationEnabled = setReplicationEnabled,
		isReplicatedToPlayer = isReplicatedToPlayer,
		itemAdded = itemAdded,
		itemRemoved = itemRemoved,
		itemChanged = itemChanged,
		cleanup = cleanup,
	}

	inventories[target] = inventory

	if target:IsA("Player") and readyPlayers[target] then
		inventory.setReplicationEnabled(target, true)
	end

	return inventory
end

function InventoryServer.getInventory(target: Instance): Types.Inventory?
	return inventories[target]
end

function InventoryServer.removeInventory(target: Instance)
	local inventory = inventories[target]
	assert(inventory, `No inventory found for target {target:GetFullName()}.`)

	for _, player in Players:GetPlayers() do
		inventory.setReplicationEnabled(player, false)
	end

	inventory.cleanup()
	inventories[target] = nil
end

function InventoryServer.transferItem(source: Instance, destination: Instance, uid: string, count: number)
	assert(source ~= destination, "Cannot transfer between the same inventory.")

	local sourceInventory = inventories[source]
	assert(sourceInventory, `No inventory found for source {source:GetFullName()}.`)
	local destinationInventory = inventories[destination]
	assert(destinationInventory, `No inventory found for destination {destination:GetFullName()}.`)

	local item = sourceInventory.getItemByUid(uid)
	assert(item, `No item found for uid {uid} in source inventory.`)

	local definition = item.definition
	sourceInventory.removeItemByUid(uid, count)
	destinationInventory.addItem(definition, count)
end

function InventoryServer.transferItems(
	source: Instance,
	destination: Instance,
	transfers: { { uid: string, count: number } }
)
	for _, transfer in transfers do
		InventoryServer.transferItem(source, destination, transfer.uid, transfer.count)
	end
end

function InventoryServer.itemToCompact(item: Item): ItemCompact
	return {
		uid = item.uid,
		definitionId = item.definition.id,
		count = item.count,
	}
end

function InventoryServer.itemFromCompact(itemCompact: ItemCompact): Item
	return {
		uid = itemCompact.uid,
		definition = itemDefinitionsById[itemCompact.definitionId],
		count = itemCompact.count,
	}
end

function InventoryServer.inventoryToCompact(inventory: Inventory): InventoryCompact
	local inventoryCompact = {
		items = {},
	}

	for _, item in inventory.getItems() do
		table.insert(inventoryCompact.items, InventoryServer.itemToCompact(item))
	end

	return inventoryCompact
end

function InventoryServer.getItemDefinition(definitionId: string): ItemDefinition
	assert(itemDefinitionsById[definitionId], "Invalid definition id")
	return itemDefinitionsById[definitionId]
end

function InventoryServer.getItemActions(owner: Types.InventoryOwner, item: Types.Item): { Types.ItemAction }
	local definition = item.definition
	if not definition.behaviors then
		return {}
	end

	local inventory = inventories[owner]
	assert(inventory, "No inventory found for owner")

	local context: Types.ItemBehaviorContext = {
		owner = owner,
		inventory = inventory,
		item = item,
	}

	local actions: { Types.ItemAction } = {}
	for _, behavior in definition.behaviors do
		for _, action in behavior.getActions(context) do
			table.insert(actions, action)
		end
	end

	table.sort(actions, function(a: Types.ItemAction, b: Types.ItemAction)
		return a.displayOrder < b.displayOrder
	end)

	return actions
end

function InventoryServer.triggerItemAction(
	owner: Types.InventoryOwner,
	actionName: string,
	itemUid: string,
	actionParams: Types.ItemActionParams?
)
	local inventory = inventories[owner]
	if not inventory then
		return
	end

	local targetItem = inventory.getItemByUid(itemUid)
	if not targetItem then
		return
	end

	local definition = targetItem.definition
	if not definition.behaviors then
		return
	end

	local context: Types.ItemBehaviorContext = {
		owner = owner,
		inventory = inventory,
		item = targetItem,
		actionParams = actionParams,
	}

	for _, behavior in definition.behaviors do
		for _, action in behavior.getActions(context) do
			if action.name ~= actionName then
				continue
			end

			if behavior.validate and not behavior.validate(actionName, context) then
				return
			end

			behavior.onAction(actionName, context)
			break
		end
	end
end

local function onPlayerItemAction(
	player: Player,
	actionName: string,
	itemId: string,
	actionParams: Types.ItemActionParams?
)
	if not validateString(actionName) or not validateString(itemId) then
		return
	end

	if actionParams ~= nil and typeof(actionParams) ~= "table" then
		return
	end

	local inventory = inventories[player]
	if not inventory then
		return
	end

	InventoryServer.triggerItemAction(player, actionName, itemId, actionParams)
end

function InventoryServer.start(definitions: { [string]: Types.ItemDefinition })
	loadItemDefinitions(itemDefinitionsById, definitions)

	Remotes.ItemAction.OnServerEvent:Connect(onPlayerItemAction)
	Remotes.ClientReady.OnServerEvent:Connect(function(player: Player)
		readyPlayers[player] = true

		local inventory = inventories[player]
		if not inventory then
			return
		end

		inventory.setReplicationEnabled(player, true)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		readyPlayers[player] = nil
	end)
end

return InventoryServer
