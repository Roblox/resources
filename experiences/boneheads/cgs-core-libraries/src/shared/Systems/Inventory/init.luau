-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Core.Libraries.Signal)

local Remotes = ReplicatedStorage.Core.Systems.Inventory.Remotes

local Types = require(script.Types)
local loadItemDefinitions = require(script.loadItemDefinitions)

local localPlayer = Players.LocalPlayer

export type ItemDefinition = Types.ItemDefinition
export type Item = Types.Item
export type Inventory = Types.Inventory
export type ItemAction = Types.ItemAction
export type ItemBehavior = Types.ItemBehavior
export type ItemBehaviorContext = Types.ItemBehaviorContext

local itemDefinitionsById: { [string]: Types.ItemDefinition } = {}
local inventories: { [Instance]: Types.Inventory } = {}
local pendingCallbacks: { [Instance]: { [(Types.Inventory) -> ()]: boolean } } = {}

local InventoryClient = {}

local function createInventory(): Types.Inventory
	local itemsByDefinitionId: { [string]: { Types.Item } } = {}
	local itemCountByDefinitionId: { [string]: number } = {}
	local itemByUid: { [string]: Types.Item } = {}
	local changeSignal = Signal.create()

	local function subscribe(callback: () -> ()): () -> ()
		return changeSignal:Connect(callback)
	end

	local function getItems(): { Types.Item }
		local result: { Types.Item } = {}
		for _, definitionItems in itemsByDefinitionId do
			for _, item in definitionItems do
				table.insert(result, item)
			end
		end
		return result
	end

	local function getItemCount(definition: Types.ItemDefinition): number
		local itemCount = itemCountByDefinitionId[definition.id]
		if not itemCount then
			return 0
		end
		return itemCount
	end

	local function getItemByUid(uid: string): Types.Item?
		return itemByUid[uid]
	end

	local function removeItemByUid(_uid: string, _count: number)
		-- TODO: implement client predictive behavior, currently managed via server-authoritative InventoryUpdate replication
	end

	local function removeItem(_definition: Types.ItemDefinition, _count: number)
		-- TODO: implement client predictive behavior, currently managed via server-authoritative InventoryUpdate replication
	end

	local function addItem(_definition: Types.ItemDefinition, _count: number)
		-- TODO: implement client predictive behavior, currently managed via server-authoritative InventoryUpdate replication
	end

	local function registerItem(item: Types.Item)
		local definitionId = item.definition.id

		if not itemsByDefinitionId[definitionId] then
			itemsByDefinitionId[definitionId] = {}
		end
		table.insert(itemsByDefinitionId[definitionId], item)

		if itemCountByDefinitionId[definitionId] == nil then
			itemCountByDefinitionId[definitionId] = 0
		end
		itemCountByDefinitionId[definitionId] += item.count

		itemByUid[item.uid] = item
	end

	local function applySnapshot(items: { Types.ItemCompact })
		itemsByDefinitionId = {}
		itemCountByDefinitionId = {}
		itemByUid = {}

		for _, itemCompact in items do
			local definition = itemDefinitionsById[itemCompact.definitionId]
			assert(definition, `Item definition not found for id: {itemCompact.definitionId}`)

			local item: Types.Item = {
				uid = itemCompact.uid,
				definition = definition,
				count = itemCompact.count,
			}
			registerItem(item)
		end

		changeSignal:Fire()
	end

	local function applyUpdate(updates: { Types.ItemUpdate })
		for _, update in updates do
			if update.type == "addItem" then
				local definition = itemDefinitionsById[update.definitionId]
				assert(definition, `Item definition not found for id: {update.definitionId}`)

				local item: Types.Item = {
					uid = update.uid,
					definition = definition,
					count = update.count,
				}
				registerItem(item)
			elseif update.type == "updateItem" then
				local existingItem = itemByUid[update.uid]
				assert(existingItem, `Item not found for uid: {update.uid}`)

				local definitionId = existingItem.definition.id
				local oldCount = existingItem.count
				existingItem.count = update.count
				itemCountByDefinitionId[definitionId] += update.count - oldCount
			elseif update.type == "removeItem" then
				local existingItem = itemByUid[update.uid]
				assert(existingItem, `Item not found for uid: {update.uid}`)

				local definitionId = existingItem.definition.id
				itemCountByDefinitionId[definitionId] -= existingItem.count
				itemByUid[update.uid] = nil

				local items = itemsByDefinitionId[definitionId]
				table.remove(items, table.find(items, existingItem))
				if next(items) == nil then
					itemsByDefinitionId[definitionId] = nil
				end
				if itemCountByDefinitionId[definitionId] == 0 then
					itemCountByDefinitionId[definitionId] = nil
				end
			end
		end

		changeSignal:Fire()
	end

	return {
		getItems = getItems,
		getItemCount = getItemCount,
		getItemByUid = getItemByUid,
		removeItemByUid = removeItemByUid,
		removeItem = removeItem,
		addItem = addItem,
		applySnapshot = applySnapshot,
		applyUpdate = applyUpdate,
		subscribe = subscribe,
	}
end

function InventoryClient.getInventory(target: Instance): Types.Inventory?
	return inventories[target]
end

function InventoryClient.onInventoryCreated(target: Instance, callback: (Types.Inventory) -> ()): () -> ()
	local inventory = inventories[target]
	if inventory then
		callback(inventory)
		return function() end
	end

	if not pendingCallbacks[target] then
		pendingCallbacks[target] = {}
	end
	pendingCallbacks[target][callback] = true

	return function()
		local callbacks = pendingCallbacks[target]
		if not callbacks then
			return
		end
		callbacks[callback] = nil
	end
end

function InventoryClient.getItemActions(item: Types.Item): { Types.ItemAction }
	local definition = item.definition
	if not definition.behaviors then
		return {}
	end

	local inventory = inventories[localPlayer]
	assert(inventory, "No inventory found for local player")

	local context: Types.ItemBehaviorContext = {
		owner = localPlayer,
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

function InventoryClient.triggerItemAction(actionName: string, itemId: string, actionParams: Types.ItemActionParams?)
	-- TODO: trigger client inventory behavior for predicted actions
	Remotes.ItemAction:FireServer(actionName, itemId, actionParams)
end

function InventoryClient.start(definitions: { [string]: Types.ItemDefinition })
	loadItemDefinitions(itemDefinitionsById, definitions)

	Remotes.InventorySnapshot.OnClientEvent:Connect(function(target: Instance, items: { Types.ItemCompact })
		if items == nil and inventories[target] then
			inventories[target].applySnapshot({})
			inventories[target] = nil
			return
		end

		if not inventories[target] then
			inventories[target] = createInventory()
		end
		local inventory = inventories[target]
		inventory.applySnapshot(items)

		local callbacks = pendingCallbacks[target]
		if callbacks then
			pendingCallbacks[target] = nil
			for callback in callbacks do
				callback(inventory)
			end
		end
	end)

	Remotes.InventoryUpdate.OnClientEvent:Connect(function(target: Instance, updates: { Types.ItemUpdate })
		assert(inventories[target], "No inventory found for target")
		local inventory = inventories[target]
		inventory.applyUpdate(updates)
	end)

	Remotes.ClientReady:FireServer()
end

return InventoryClient
