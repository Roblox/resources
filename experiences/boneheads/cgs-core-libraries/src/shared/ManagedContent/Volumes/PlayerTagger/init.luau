-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Core.Libraries.TriggerVolume.Types)

local getPlayerCharacterFromPart = require(ReplicatedStorage.Core.Utility.getPlayerCharacterFromPart)

local ASSIGNED_TAG_ATTRIBUTE = "assignedTag"

local function create(volumePart: BasePart): Types.TriggerVolume
	local tagName = volumePart:GetAttribute(ASSIGNED_TAG_ATTRIBUTE) :: string?
	assert(tagName, "PlayerTagger missing assigned tag")

	local function onEnter(character: PVInstance)
		character:AddTag(tagName)
	end

	local function onExit(character: PVInstance)
		character:RemoveTag(tagName)
	end

	return {
		onEnter = onEnter,
		onExit = onExit,
	}
end

local PlayerTagger: Types.TriggerVolumeDefinition = {
	create = create,
	filter = getPlayerCharacterFromPart,
}

return PlayerTagger
