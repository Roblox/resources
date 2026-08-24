-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Parent.Types)

local function makeBaseParty(id: string, leader: Player?, maxSize: number): Types.Party
	local party: Types.Party

	local function getSize(): number
		return #party.members
	end

	local function getMembers(): { Player }
		return party.members
	end

	local function getReadyMembers(): { Player }
		return party.readyMembers
	end

	local function isReady(): boolean
		if #party.members == 0 then
			return false
		end

		return #party.readyMembers == #party.members
	end

	local function cleanup()
		table.clear(party.members)
		table.clear(party.readyMembers)
	end

	party = {
		id = id,
		leader = leader,
		maxSize = maxSize,
		members = {},
		readyMembers = {},

		getSize = getSize,
		getMembers = getMembers,
		getReadyMembers = getReadyMembers,
		isReady = isReady,
		cleanup = cleanup,
	}

	return party
end

return makeBaseParty
