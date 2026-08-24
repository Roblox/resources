-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Core.Constants)

local function getCharacterFromPart(part: PVInstance): Model?
	local model = if part:IsA("Model") then part else part:FindFirstAncestorOfClass("Model")
	if model and model:HasTag(Constants.TAGS.CHARACTER) then
		return model
	end

	return nil
end

return getCharacterFromPart
