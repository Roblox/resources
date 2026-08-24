-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local validateInstance = require(script.Parent.validateInstance)

local function validateTool(tool: Instance, player: Player, requireEquipped: boolean): boolean
	if not validateInstance(tool, "Instance") then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end

	local backpack = character:FindFirstChildWhichIsA("Backpack")
	local tools = backpack and backpack:FindFirstChild("Tools")
	local equipped = backpack and backpack:FindFirstChild("Equipped")
	assert(tools, "Missing Tools")
	assert(equipped and equipped:IsA("ObjectValue"), "Missing ObjectValue")

	if requireEquipped then
		return equipped.Value == tool and tool.Parent == tools
	else
		return tool.Parent == tools
	end
end

return validateTool
