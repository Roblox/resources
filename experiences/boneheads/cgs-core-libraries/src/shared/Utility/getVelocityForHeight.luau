-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local function getVelocityForHeight(height: number): number
	return math.sqrt(2 * Workspace.Gravity * height)
end

return getVelocityForHeight
