-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ReplicatedStorage.Core.Systems.Inventory.Types)
local makeEquippable = require(ReplicatedStorage.Core.ManagedContent.Inventory.BehaviorFactories.makeEquippable)
local validateInstance = require(ServerScriptService.Core.Validation.validateInstance)
local validateString = require(ServerScriptService.Core.Validation.validateString)

local Equippable = makeEquippable({
	validate = function(actionName: string, context: Types.ItemBehaviorContext): boolean
		if not validateString(actionName) then
			return false
		end

		local owner = context.owner
		local character = if owner:IsA("Player") then owner.Character else owner
		if not character or not validateInstance(character, "Model") then
			return false
		end

		return true
	end,
	isEquipped = function(_context: Types.ItemBehaviorContext): boolean
		-- TODO: project-specific equip state check
		return false
	end,
	onEquip = function(_context: Types.ItemBehaviorContext)
		-- TODO: project-specific equip logic
	end,
	onUnequip = function(_context: Types.ItemBehaviorContext)
		-- TODO: project-specific unequip logic
	end,
})

return Equippable
