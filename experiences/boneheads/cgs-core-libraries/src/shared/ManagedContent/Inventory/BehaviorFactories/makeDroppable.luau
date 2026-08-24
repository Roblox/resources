-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Core.Systems.Inventory.Types)

export type DroppableParams = {
	actionName: string?,
	actionDisplayOrder: number?,
	validate: ((actionName: string, context: Types.ItemBehaviorContext) -> boolean)?,
	onDrop: (context: Types.ItemBehaviorContext) -> (),
}

local DEFAULT_ACTION_NAME = "Drop"
local DEFAULT_ACTION_DISPLAY_ORDER = 3

local function makeDroppable(params: DroppableParams): Types.ItemBehavior
	local action: Types.ItemAction = {
		name = params.actionName or DEFAULT_ACTION_NAME,
		displayOrder = params.actionDisplayOrder or DEFAULT_ACTION_DISPLAY_ORDER,
	}

	local function getActions(_context: Types.ItemBehaviorContext): { Types.ItemAction }
		return { action }
	end

	local function onAction(_actionName: string, context: Types.ItemBehaviorContext)
		params.onDrop(context)
	end

	return {
		getActions = getActions,
		onAction = onAction,
		validate = params.validate,
	}
end

return makeDroppable
