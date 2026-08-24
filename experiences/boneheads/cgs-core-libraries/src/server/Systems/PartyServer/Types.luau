-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(ReplicatedStorage.Core.Systems.Party.Types)
local Signal = require(ReplicatedStorage.Core.Libraries.Signal)

export type ServerParty = SharedTypes.Party & {
	expectedLeaderId: number,
	expectedMemberIds: { number },

	isAssembled: () -> boolean,
	assembled: Signal.Signal<>,

	addMember: (player: Player) -> (),
	removeMember: (player: Player) -> (),
	setMemberReady: (player: Player, ready: boolean) -> (),
	setLeader: (player: Player) -> (),

	addPendingInvite: (player: Player) -> (),
	removePendingInvite: (player: Player) -> (),
	hasPendingInvite: (player: Player) -> boolean,
}

export type ServerPartyParams = {
	id: string,
	maxSize: number,

	leader: Player?,
	expectedLeaderId: number?,
	expectedMemberIds: { number },
}

return nil
