-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Core.Systems.Inventory.Types)
local makeDiscardable = require(ReplicatedStorage.Core.ManagedContent.Inventory.BehaviorFactories.makeDiscardable)

local Discardable = makeDiscardable({
	onDiscard = function(_context: Types.ItemBehaviorContext)
		-- TODO: Client predictive behavior
	end,
})

return Discardable
