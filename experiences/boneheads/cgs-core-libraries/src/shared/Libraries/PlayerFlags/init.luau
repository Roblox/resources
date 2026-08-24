-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Constants = require(script.Constants)

export type FlagValue = boolean | number

local function getFlagAttribute(flag: string): string
	return `{Constants.FLAG_ATTRIBUTE_PREFIX}{flag}`
end

local PlayerFlags = {}

function PlayerFlags.setFlag(player: Player, flag: string, value: FlagValue?)
	value = if value ~= nil then value else Constants.FLAG_DEFAULT_VALUE
	player:SetAttribute(getFlagAttribute(flag), value)

	-- TODO: Save to datastore
end

function PlayerFlags.clearFlag(player: Player, flag: string)
	player:SetAttribute(getFlagAttribute(flag), nil)

	-- TODO: Save to datastore
end

function PlayerFlags.clearFlags(player: Player)
	for attributeName in pairs(player:GetAttributes()) do
		if string.sub(attributeName, 1, #Constants.FLAG_ATTRIBUTE_PREFIX) ~= Constants.FLAG_ATTRIBUTE_PREFIX then
			continue
		end

		local flagName = string.sub(attributeName, #Constants.FLAG_ATTRIBUTE_PREFIX + 1)
		PlayerFlags.clearFlag(player, flagName)
	end
end

function PlayerFlags.getFlag(player: Player, flag: string): FlagValue?
	return player:GetAttribute(getFlagAttribute(flag)) :: FlagValue?
end

function PlayerFlags.hasFlag(player: Player, flag: string): boolean
	local value = PlayerFlags.getFlag(player, flag)
	return value ~= nil and value ~= false
end

function PlayerFlags.getFlagChangedSignal(
	player: Player,
	flag: string,
	callback: (FlagValue?) -> ()
): RBXScriptConnection
	return player:GetAttributeChangedSignal(getFlagAttribute(flag)):Connect(function()
		callback(PlayerFlags.getFlag(player, flag))
	end)
end

return PlayerFlags
