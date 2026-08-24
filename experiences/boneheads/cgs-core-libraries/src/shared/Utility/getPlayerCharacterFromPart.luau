-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Core.Constants)

local getCharacterFromPart = require(ReplicatedStorage.Core.Utility.getCharacterFromPart)

local function getPlayerCharacterFromPart(part: BasePart): Model?
	local character = getCharacterFromPart(part)
	if character and character:HasTag(Constants.TAGS.PLAYER) then
		return character
	end

	return nil
end

return getPlayerCharacterFromPart
