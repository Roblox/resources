-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Core.Systems.Inventory.Types)

export type EquippableParams = {
	equipActionName: string?,
	unequipActionName: string?,
	actionDisplayOrder: number?,
	validate: ((actionName: string, context: Types.ItemBehaviorContext) -> boolean)?,
	isEquipped: (context: Types.ItemBehaviorContext) -> boolean,
	onEquip: (context: Types.ItemBehaviorContext) -> (),
	onUnequip: (context: Types.ItemBehaviorContext) -> (),
}

local DEFAULT_EQUIP_ACTION_NAME = "Equip"
local DEFAULT_UNEQUIP_ACTION_NAME = "Unequip"
local DEFAULT_ACTION_DISPLAY_ORDER = 1

local function makeEquippable(params: EquippableParams): Types.ItemBehavior
	local equipAction: Types.ItemAction = {
		name = params.equipActionName or DEFAULT_EQUIP_ACTION_NAME,
		displayOrder = params.actionDisplayOrder or DEFAULT_ACTION_DISPLAY_ORDER,
	}

	local unequipAction: Types.ItemAction = {
		name = params.unequipActionName or DEFAULT_UNEQUIP_ACTION_NAME,
		displayOrder = params.actionDisplayOrder or DEFAULT_ACTION_DISPLAY_ORDER,
	}

	local function getActions(context: Types.ItemBehaviorContext): { Types.ItemAction }
		if params.isEquipped(context) then
			return { unequipAction }
		else
			return { equipAction }
		end
	end

	local function onAction(actionName: string, context: Types.ItemBehaviorContext)
		if actionName == equipAction.name then
			params.onEquip(context)
		elseif actionName == unequipAction.name then
			params.onUnequip(context)
		end
	end

	return {
		getActions = getActions,
		onAction = onAction,
		validate = params.validate,
	}
end

return makeEquippable
