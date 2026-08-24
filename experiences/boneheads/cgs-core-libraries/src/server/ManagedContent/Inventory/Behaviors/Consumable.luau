-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ReplicatedStorage.Core.Systems.Inventory.Types)
local makeConsumable = require(ReplicatedStorage.Core.ManagedContent.Inventory.BehaviorFactories.makeConsumable)
local validateString = require(ServerScriptService.Core.Validation.validateString)

local Consumable = makeConsumable({
	validate = function(actionName: string, context: Types.ItemBehaviorContext): boolean
		if not validateString(actionName) then
			return false
		end

		if not validateString(context.item.uid) then
			return false
		end

		return true
	end,
	onConsume = function(context: Types.ItemBehaviorContext)
		context.inventory.removeItemByUid(context.item.uid, 1)
	end,
})

return Consumable
