-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ReplicatedStorage.Core.Systems.Inventory.Types)
local makeDiscardable = require(ReplicatedStorage.Core.ManagedContent.Inventory.BehaviorFactories.makeDiscardable)
local validateString = require(ServerScriptService.Core.Validation.validateString)

local Discardable = makeDiscardable({
	validate = function(actionName: string, context: Types.ItemBehaviorContext): boolean
		if not validateString(actionName) then
			return false
		end

		if not validateString(context.item.uid) then
			return false
		end

		return true
	end,
	onDiscard = function(context: Types.ItemBehaviorContext)
		context.inventory.removeItemByUid(context.item.uid, 1)
	end,
})

return Discardable
