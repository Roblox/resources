-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Core.Systems.Inventory.Types)
local makeEquippable = require(ReplicatedStorage.Core.ManagedContent.Inventory.BehaviorFactories.makeEquippable)

local Equippable = makeEquippable({
	isEquipped = function(_context: Types.ItemBehaviorContext): boolean
		-- TODO: project-specific equip state check
		return false
	end,
	onEquip = function(_context: Types.ItemBehaviorContext)
		-- TODO: Client predictive behavior
	end,
	onUnequip = function(_context: Types.ItemBehaviorContext)
		-- TODO: Client predictive behavior
	end,
})

return Equippable
