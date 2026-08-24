-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

if RunService:IsServer() then
	return require(ServerScriptService.Core.ManagedContent.Inventory.Behaviors)
end

return {
	Consumable = require(script.Consumable),
	Discardable = require(script.Discardable),
	Droppable = require(script.Droppable),
	Equippable = require(script.Equippable),
}
