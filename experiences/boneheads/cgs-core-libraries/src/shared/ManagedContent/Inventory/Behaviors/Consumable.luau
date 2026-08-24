-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Core.Systems.Inventory.Types)
local makeConsumable = require(ReplicatedStorage.Core.ManagedContent.Inventory.BehaviorFactories.makeConsumable)

local Consumable = makeConsumable({
	onConsume = function(_context: Types.ItemBehaviorContext)
		-- TODO: Client predictive behavior
	end,
})

return Consumable
